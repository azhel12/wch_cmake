set(CH32_SUPPORTED_FAMILIES_LONG_NAME
    CH32V0 CH32V1 CH32V2 CH32V3
    # TODO:: Append L, X series
)
    
foreach(FAMILY ${CH32_SUPPORTED_FAMILIES_LONG_NAME})
    # append short names (V0, V1, ...) to CH32_SUPPORTED_FAMILIES_SHORT_NAME
    string(REGEX MATCH "^CH32([VLX]P?[0-9BL])" FAMILY ${FAMILY})
    list(APPEND CH32_SUPPORTED_FAMILIES_SHORT_NAME ${CMAKE_MATCH_1})
endforeach()
list(REMOVE_DUPLICATES CH32_SUPPORTED_FAMILIES_SHORT_NAME)

if(NOT CH32_TOOLCHAIN_PATH)
    if(DEFINED ENV{CH32_TOOLCHAIN_PATH})
        message(STATUS "Detected toolchain path CH32_TOOLCHAIN_PATH in environmental variables: ")
        message(STATUS "$ENV{CH32_TOOLCHAIN_PATH}")
        set(CH32_TOOLCHAIN_PATH $ENV{CH32_TOOLCHAIN_PATH})
    else()
        if(NOT CMAKE_C_COMPILER)
            set(CH32_TOOLCHAIN_PATH "/usr")
            message(STATUS "No CH32_TOOLCHAIN_PATH specified, using default: " ${CH32_TOOLCHAIN_PATH})
        else()
            # keep only directory of compiler
            get_filename_component(CH32_TOOLCHAIN_PATH ${CMAKE_C_COMPILER} DIRECTORY)
            # remove the last /bin directory
            get_filename_component(CH32_TOOLCHAIN_PATH ${CH32_TOOLCHAIN_PATH} DIRECTORY)
        endif()
    endif()
    file(TO_CMAKE_PATH "${CH32_TOOLCHAIN_PATH}" CH32_TOOLCHAIN_PATH)
endif()

if(NOT CH32_TARGET_TRIPLET)
    set(CH32_TARGET_TRIPLET "riscv-none-elf")
    message(STATUS "No CH32_TARGET_TRIPLET specified, using default: " ${CH32_TARGET_TRIPLET})
endif()

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv)

set(TOOLCHAIN_SYSROOT  "${CH32_TOOLCHAIN_PATH}/${CH32_TARGET_TRIPLET}")
set(TOOLCHAIN_BIN_PATH "${CH32_TOOLCHAIN_PATH}/bin")
set(TOOLCHAIN_INC_PATH "${CH32_TOOLCHAIN_PATH}/${CH32_TARGET_TRIPLET}/include")
set(TOOLCHAIN_LIB_PATH "${CH32_TOOLCHAIN_PATH}/${CH32_TARGET_TRIPLET}/lib")

set(CMAKE_SYSROOT ${TOOLCHAIN_SYSROOT})

find_program(CMAKE_OBJCOPY NAMES ${CH32_TARGET_TRIPLET}-objcopy HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_OBJDUMP NAMES ${CH32_TARGET_TRIPLET}-objdump HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_SIZE NAMES ${CH32_TARGET_TRIPLET}-size HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_DEBUGGER NAMES ${CH32_TARGET_TRIPLET}-gdb HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_CPPFILT NAMES ${CH32_TARGET_TRIPLET}-c++filt HINTS ${TOOLCHAIN_BIN_PATH})

# This function adds a target with name '${TARGET}_always_display_size'. The new
# target builds a TARGET and then calls the program defined in CMAKE_SIZE to
# display the size of the final ELF.
function(ch32_print_size_of_target TARGET)
    add_custom_target(${TARGET}_always_display_size
        ALL COMMAND ${CMAKE_SIZE} "$<TARGET_FILE:${TARGET}>"
        COMMENT "Target Sizes: "
        DEPENDS ${TARGET}
    )
endfunction()

# This function calls the objcopy program defined in CMAKE_OBJCOPY to generate
# file with object format specified in OBJCOPY_BFD_OUTPUT.
# The generated file has the name of the target output but with extension
# corresponding to the OUTPUT_EXTENSION argument value.
# The generated file will be placed in the same directory as the target output file.
function(_ch32_generate_file TARGET OUTPUT_EXTENSION OBJCOPY_BFD_OUTPUT)
    get_target_property(TARGET_OUTPUT_NAME ${TARGET} OUTPUT_NAME)
    if (TARGET_OUTPUT_NAME)
        set(OUTPUT_FILE_NAME "${TARGET_OUTPUT_NAME}.${OUTPUT_EXTENSION}")
    else()
        set(OUTPUT_FILE_NAME "${TARGET}.${OUTPUT_EXTENSION}")
    endif()

    get_target_property(RUNTIME_OUTPUT_DIRECTORY ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
    if(RUNTIME_OUTPUT_DIRECTORY)
        set(OUTPUT_FILE_PATH "${RUNTIME_OUTPUT_DIRECTORY}/${OUTPUT_FILE_NAME}")
    else()
        set(OUTPUT_FILE_PATH "${OUTPUT_FILE_NAME}")
    endif()

    add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ${OBJCOPY_BFD_OUTPUT} "$<TARGET_FILE:${TARGET}>" ${OUTPUT_FILE_PATH}
        BYPRODUCTS ${OUTPUT_FILE_PATH}
        COMMENT "Generating ${OBJCOPY_BFD_OUTPUT} file ${OUTPUT_FILE_NAME}"
    )
endfunction()

# This function adds post-build generation of the binary file from the target ELF.
# The generated file will be placed in the same directory as the ELF file.
function(ch32_generate_binary_file TARGET)
    _ch32_generate_file(${TARGET} "bin" "binary")
endfunction()

# This function adds post-build generation of the Motorola S-record file from the target ELF.
# The generated file will be placed in the same directory as the ELF file.
function(ch32_generate_srec_file TARGET)
    _ch32_generate_file(${TARGET} "srec" "srec")
endfunction()

# This function adds post-build generation of the Intel hex file from the target ELF.
# The generated file will be placed in the same directory as the ELF file.
function(ch32_generate_hex_file TARGET)
    _ch32_generate_file(${TARGET} "hex" "ihex")
endfunction()

# This function takes FAMILY (e.g. L4) and DEVICE (e.g. L496VG) to output TYPE (e.g. L496xx)
function(ch32_get_chip_type FAMILY DEVICE TYPE)
    set(INDEX 0)
    foreach(C_TYPE ${CH32_${FAMILY}_TYPES})
        list(GET CH32_${FAMILY}_TYPE_MATCH ${INDEX} REGEXP)
        if(${DEVICE} MATCHES ${REGEXP})
            set(RESULT_TYPE ${C_TYPE})
        endif()
        math(EXPR INDEX "${INDEX}+1")
    endforeach()
    if(NOT RESULT_TYPE)
        message(FATAL_ERROR "Invalid/unsupported device: ${DEVICE}")
    endif()
    set(${TYPE} ${RESULT_TYPE} PARENT_SCOPE)
endfunction()

function(ch32_get_chip_info CHIP)
    set(ARG_OPTIONS "")
    set(ARG_SINGLE FAMILY DEVICE TYPE)
    set(ARG_MULTIPLE "")
    cmake_parse_arguments(PARSE_ARGV 1 ARG "${ARG_OPTIONS}" "${ARG_SINGLE}" "${ARG_MULTIPLE}")

    string(TOUPPER ${CHIP} CHIP)

    #TODO:: Maybe write more accurate pattern, for example last [0-9A-Z] replace with [4678BC] etc
    string(REGEX MATCH "^CH32([VLX]P?[0-3])([0-9][0-9][A-Z][0-9A-Z]).*$" CHIP ${CHIP})

    if((NOT CMAKE_MATCH_1) OR (NOT CMAKE_MATCH_2))
        message(FATAL_ERROR "Unknown chip ${CHIP}")
    endif()

    set(CH32_FAMILY ${CMAKE_MATCH_1})
    set(CH32_DEVICE "${CMAKE_MATCH_1}${CMAKE_MATCH_2}")


    if(NOT (${CH32_FAMILY} IN_LIST CH32_SUPPORTED_FAMILIES_SHORT_NAME))
        message(FATAL_ERROR "Unsupported family ${CH32_FAMILY} for device ${CHIP}")
    endif()

    ch32_get_chip_type(${CH32_FAMILY} ${CH32_DEVICE} CH32_TYPE)

    if(ARG_FAMILY)
        set(${ARG_FAMILY} ${CH32_FAMILY} PARENT_SCOPE)
    endif()
    if(ARG_DEVICE)
        set(${ARG_DEVICE} ${CH32_DEVICE} PARENT_SCOPE)
    endif()
    if(ARG_TYPE)
        set(${ARG_TYPE} ${CH32_TYPE} PARENT_SCOPE)
    endif()
endfunction()

function(ch32_get_memory_info)
    set(ARG_OPTIONS FLASH RAM CCRAM STACK HEAP RAM_SHARE)
    set(ARG_SINGLE CHIP FAMILY DEVICE SIZE ORIGIN)
    set(ARG_MULTIPLE "")
    cmake_parse_arguments(INFO "${ARG_OPTIONS}" "${ARG_SINGLE}" "${ARG_MULTIPLE}" ${ARGN})

    if((NOT INFO_CHIP) AND ((NOT INFO_FAMILY) OR (NOT INFO_DEVICE)))
        message(FATAL_ERROR "Either CHIP or FAMILY/DEVICE is required for ch32_get_memory_info()")
    endif()

    if(INFO_CHIP)
        ch32_get_chip_info(${INFO_CHIP} FAMILY INFO_FAMILY TYPE INFO_TYPE DEVICE INFO_DEVICE)
    else()
        ch32_get_chip_type(${INFO_FAMILY} ${INFO_DEVICE} INFO_TYPE)
    endif()

    string(REGEX REPLACE "^[LVX]P?[0-3][0-9][0-9].([4678BC])$" "\\1" SIZE_CODE ${INFO_DEVICE})

    if(SIZE_CODE STREQUAL "4")
        set(FLASH "16K")
    elseif(SIZE_CODE STREQUAL "6")
        set(FLASH "32K")
    elseif(SIZE_CODE STREQUAL "7")
        set(FLASH "48")
    elseif(SIZE_CODE STREQUAL "8")
        set(FLASH "64K")
    elseif(SIZE_CODE STREQUAL "B")
        set(FLASH "128K")
    elseif(SIZE_CODE STREQUAL "C")
        set(FLASH "256K")
    else()
        set(FLASH "16K")
        message(WARNING "Unknow flash size for device ${DEVICE}. Set to ${FLASH}")
    endif()

    list(FIND CH32_${INFO_FAMILY}_TYPES ${INFO_TYPE} TYPE_INDEX)
    list(GET CH32_${INFO_FAMILY}_RAM_SIZES ${TYPE_INDEX} RAM)
    set(FLASH_ORIGIN 0x0000000)
    set(RAM_ORIGIN 0x20000000)

    unset(TWO_FLASH_BANKS)

    if(INFO_FLASH)
        set(SIZE ${FLASH})
        set(ORIGIN ${FLASH_ORIGIN})
    elseif(INFO_RAM)
        set(SIZE ${RAM})
        set(ORIGIN ${RAM_ORIGIN})
    elseif(INFO_STACK)
        if (RAM STREQUAL "2K")
            set(SIZE 0x200)
        else()
            set(SIZE 0x400)
        endif()
        set(ORIGIN ${RAM_ORIGIN}) #TODO: Real stack pointer?
    elseif(INFO_HEAP)
        if (RAM STREQUAL "2K")
            set(SIZE 0x100)
        else()
            set(SIZE 0x200)
        endif()
        set(ORIGIN ${RAM_ORIGIN}) #TODO: Real heap pointer?
    endif()

    if(INFO_SIZE)
        set(${INFO_SIZE} ${SIZE} PARENT_SCOPE)
    endif()
    if(INFO_ORIGIN)
        set(${INFO_ORIGIN} ${ORIGIN} PARENT_SCOPE)
    endif()
endfunction()

function(ch32_add_linker_script TARGET VISIBILITY SCRIPT)
    get_filename_component(SCRIPT "${SCRIPT}" ABSOLUTE)
    target_link_options(${TARGET} ${VISIBILITY} -T "${SCRIPT}")

    get_target_property(TARGET_TYPE ${TARGET} TYPE)
    if(TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
        set(INTERFACE_PREFIX "INTERFACE_")
    endif()

    get_target_property(LINK_DEPENDS ${TARGET} ${INTERFACE_PREFIX}LINK_DEPENDS)
    if(LINK_DEPENDS)
        list(APPEND LINK_DEPENDS "${SCRIPT}")
    else()
        set(LINK_DEPENDS "${SCRIPT}")
    endif()


    set_target_properties(${TARGET} PROPERTIES ${INTERFACE_PREFIX}LINK_DEPENDS "${LINK_DEPENDS}")
endfunction()

if(NOT (TARGET CH32::NoSys))
    add_library(CH32::NoSys INTERFACE IMPORTED)
    target_compile_options(CH32::NoSys INTERFACE $<$<C_COMPILER_ID:GNU>:--specs=nosys.specs>)
    target_link_options(CH32::NoSys INTERFACE $<$<C_COMPILER_ID:GNU>:--specs=nosys.specs>)
endif()

if(NOT (TARGET CH32::Nano))
    add_library(CH32::Nano INTERFACE IMPORTED)
    target_compile_options(CH32::Nano INTERFACE $<$<C_COMPILER_ID:GNU>:--specs=nano.specs>)
    target_link_options(CH32::Nano INTERFACE $<$<C_COMPILER_ID:GNU>:--specs=nano.specs>)
endif()

if(NOT (TARGET CH32::Nano::FloatPrint))
    add_library(CH32::Nano::FloatPrint INTERFACE IMPORTED)
    target_link_options(CH32::Nano::FloatPrint INTERFACE
        $<$<C_COMPILER_ID:GNU>:-Wl,--undefined,_printf_float>
    )
endif()

if(NOT (TARGET CH32::Nano::FloatScan))
    add_library(CH32::Nano::FloatScan INTERFACE IMPORTED)
    target_link_options(CH32::Nano::FloatScan INTERFACE
        $<$<C_COMPILER_ID:GNU>:-Wl,--undefined,_scanf_float>
    )
endif()

include(ch32/utilities)
include(ch32/v0)
#include(ch32/v1)
include(ch32/v2)
#include(ch32/v3)

