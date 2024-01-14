function(file_remove_pattern FILENAME PATTERN)
    file(READ ${FILENAME} FILE_CONTENTS)
    string(REPLACE "${PATTERN}" "" FILE_CONTENTS "${FILE_CONTENTS}")
    file(WRITE ${FILENAME} "${FILE_CONTENTS}")
endfunction()

function(file_remove_regex FILENAME PATTERN)
    file(READ ${FILENAME} FILE_CONTENTS)
    string(REGEX REPLACE "${PATTERN}" "" FILE_CONTENTS "${FILE_CONTENTS}")
    file(WRITE ${FILENAME} "${FILE_CONTENTS}")
endfunction()

function(file_replace FILENAME PATTERN REPLACE)
    file(READ ${FILENAME} FILE_CONTENTS)
    string(REGEX REPLACE "${PATTERN}" "${REPLACE}" FILE_CONTENTS "${FILE_CONTENTS}")
    file(WRITE ${FILENAME} "${FILE_CONTENTS}")
endfunction()

function(ch32_util_create_family_targets FAMILY)
    set(CORES ${ARGN})
    list(LENGTH CORES NUM_CORES)
    if(${NUM_CORES} EQUAL 0)
        set(CORE "")
        set(CORE_C "")
    elseif(${NUM_CORES} EQUAL 1)
        set(CORE "_${CORES}")
        set(CORE_C "::${CORES}")
    else()
        message(FATAL_ERROR "Expected at most one core for family ${FAMILY}: ${CORES}")
    endif()

    if(NOT (TARGET CH32::${FAMILY}${CORE_C}))
        add_library(CH32::${FAMILY}${CORE_C} INTERFACE IMPORTED)
        # Set compiler flags for target
        # -Wall: all warnings activated
        # -ffunction-sections -fdata-sections: remove unused code
        target_compile_options(CH32::${FAMILY}${CORE_C} INTERFACE 
            -Wall -ffunction-sections -fdata-sections
        )
        # Set linker flags
        # -Wl,--gc-sections: Remove unused code
        target_link_options(CH32::${FAMILY}${CORE_C} INTERFACE 
            -Wl,--gc-sections
        )
        target_compile_definitions(CH32::${FAMILY}${CORE_C} INTERFACE 
            CH32${FAMILY}
        )
    endif()
    foreach(TYPE ${CH32_${FAMILY}_TYPES})
        if(NOT (TARGET CH32::${TYPE}${CORE_C}))
            add_library(CH32::${TYPE}${CORE_C} INTERFACE IMPORTED)
            target_link_libraries(CH32::${TYPE}${CORE_C} INTERFACE CH32::${FAMILY}${CORE_C})
            target_compile_definitions(CH32::${TYPE}${CORE_C} INTERFACE 
                CH32${TYPE}
            )
        endif()
    endforeach()
endfunction()

include(FetchContent)

FetchContent_Declare(
    CH32-LIBS
    GIT_REPOSITORY https://github.com/azhel12/wch_libs/
    GIT_PROGRESS   TRUE
)

function(ch32_fetch_cmsis)
    if(NOT CH32_LIBS_PATH)
        FetchContent_MakeAvailable(CH32-LIBS)
        set(CH32_LIBS_PATH ${ch32-libs_SOURCE_DIR})
    else()
        message("CH32_LIBS_PATH specified, skipping fetch for CH32-LIBS")
    endif()

    foreach(FAMILY ${ARGV})
        set(CH32_CMSIS_${FAMILY}_PATH ${CH32_LIBS_PATH}/CH32${FAMILY}0x PARENT_SCOPE)
    endforeach()
endfunction()

function(ch32_fetch_spl)
    if(NOT CH32_LIBS_PATH)
        FetchContent_MakeAvailable(CH32-LIBS)
        set(CH32_LIBS_PATH ${ch32-libs_SOURCE_DIR})
    else()
        message(INFO "CH32_LIBS_PATH specified, skipping fetch for CH32-LIBS")
    endif()

    foreach(FAMILY ${ARGV})
        set(CH32_SPL_${FAMILY}_PATH ${CH32_LIBS_PATH}/CH32${FAMILY}0x/spl PARENT_SCOPE)
    endforeach()
endfunction()

