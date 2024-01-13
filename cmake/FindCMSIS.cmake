if(NOT CMSIS_FIND_COMPONENTS)
    set(CMSIS_FIND_COMPONENTS ${CH32_SUPPORTED_FAMILIES_LONG_NAME})
endif()

list(REMOVE_DUPLICATES CMSIS_FIND_COMPONENTS)

# This section fills the RTOS or family components list
foreach(COMP ${CMSIS_FIND_COMPONENTS})
    string(TOLOWER ${COMP} COMP_L)
    string(TOUPPER ${COMP} COMP)

    # Component is RTOS component
    if(${COMP} IN_LIST CMSIS_RTOS)
        list(APPEND CMSIS_FIND_COMPONENTS_RTOS ${COMP})
        continue()
    endif()

    # Component is not RTOS component, so check whether it is a family component
    string(REGEX MATCH "^CH32([VLX]P?[0-3])([0-9][0-9][A-Z][0-9A-Z])?.*$" COMP ${COMP})
    if(CMAKE_MATCH_1)
        list(APPEND CMSIS_FIND_COMPONENTS_FAMILIES ${COMP})
    endif()
endforeach()

if(NOT CMSIS_FIND_COMPONENTS_FAMILIES)
    set(CMSIS_FIND_COMPONENTS_FAMILIES ${CH32_SUPPORTED_FAMILIES_LONG_NAME})
endif()

message(STATUS "Search for CMSIS families: ${CMSIS_FIND_COMPONENTS_FAMILIES}")

include(ch32/devices)

function(cmsis_generate_default_linker_script FAMILY DEVICE)    
    set(OUTPUT_LD_FILE "${CMAKE_CURRENT_BINARY_DIR}/${DEVICE}.ld")
      
    ch32_get_memory_info(FAMILY ${FAMILY} DEVICE ${DEVICE} FLASH SIZE FLASH_SIZE ORIGIN FLASH_ORIGIN)
    ch32_get_memory_info(FAMILY ${FAMILY} DEVICE ${DEVICE} RAM SIZE RAM_SIZE ORIGIN RAM_ORIGIN)
    ch32_get_memory_info(FAMILY ${FAMILY} DEVICE ${DEVICE} HEAP SIZE HEAP_SIZE)
    ch32_get_memory_info(FAMILY ${FAMILY} DEVICE ${DEVICE} STACK SIZE STACK_SIZE)

    add_custom_command(OUTPUT "${OUTPUT_LD_FILE}"
        COMMAND ${CMAKE_COMMAND} 
            -DFLASH_ORIGIN="${FLASH_ORIGIN}" 
            -DRAM_ORIGIN="${RAM_ORIGIN}" 
            -DFLASH_SIZE="${FLASH_SIZE}" 
            -DRAM_SIZE="${RAM_SIZE}" 
            -DSTACK_SIZE="${STACK_SIZE}" 
            -DHEAP_SIZE="${HEAP_SIZE}" 
            -DLINKER_SCRIPT="${OUTPUT_LD_FILE}"
            -DFAMILY="${FAMILY}"
            -P "${CH32_CMAKE_DIR}/ch32/linker_ld.cmake"
    )

    add_custom_target(CMSIS_LD_${DEVICE} DEPENDS "${OUTPUT_LD_FILE}")
    add_dependencies(CMSIS::CH32::${DEVICE} CMSIS_LD_${DEVICE})
    ch32_add_linker_script(CMSIS::CH32::${DEVICE} INTERFACE "${OUTPUT_LD_FILE}")
endfunction() 

foreach(COMP ${CMSIS_FIND_COMPONENTS_FAMILIES})
    string(TOLOWER ${COMP} COMP_L)
    string(TOUPPER ${COMP} COMP)
    
    string(REGEX MATCH "^CH32([VLX]P?[0-9])([0-9][0-9][A-Z][0-9A-Z])?.*$" COMP ${COMP})
    # CMAKE_MATCH_<n> contains n'th subexpression
    # CMAKE_MATCH_0 contains full match

    if((NOT CMAKE_MATCH_1) AND (NOT CMAKE_MATCH_2))
        message(FATAL_ERROR "Unknown CMSIS component: ${COMP}")
    endif()
    
    if(CMAKE_MATCH_2)
        set(FAMILY ${CMAKE_MATCH_1})
        set(WCH_DEVICES "${CMAKE_MATCH_1}${CMAKE_MATCH_2}")
        message(VERBOSE "FindCMSIS: full device name match for COMP ${COMP}, WCH_DEVICES is ${WCH_DEVICES}")
    else()
        set(FAMILY ${CMAKE_MATCH_1})
        ch32_get_devices_by_family(WCH_DEVICES FAMILY ${FAMILY})
        message(VERBOSE "FindCMSIS: family only match for COMP ${COMP}, WCH_DEVICES is ${WCH_DEVICES}")
    endif()
    
    string(TOLOWER ${FAMILY} FAMILY_L)

    # search for core/core_riscv.h
    find_path(CMSIS_${FAMILY}_CORE_PATH
        NAMES core_riscv.h
        PATHS "${CH32_CMSIS_${FAMILY}_PATH}/core"
        NO_DEFAULT_PATH
    )
    if (NOT CMSIS_${FAMILY}_CORE_PATH)
        message(VERBOSE "FindCMSIS: core_riscv.h for ${FAMILY} has not been found")
        continue()
    endif()

    # search for include/ch32[XX]0x.h
    find_path(CMSIS_${FAMILY}_PATH
        NAMES include/ch32${FAMILY_L}0x.h
        PATHS "${CH32_CMSIS_${FAMILY}_PATH}"
        NO_DEFAULT_PATH
    )
    if (NOT CMSIS_${FAMILY}_PATH)
        message("FindCMSIS: ch32${FAMILY_L}0x.h for ${FAMILY} has not been found")
        continue()
    endif()

    file_remove_pattern("${CMSIS_${FAMILY}_PATH}/include/ch32${FAMILY_L}0x.h" "#include <ch32${FAMILY_L}0x_conf.h>")
    file_remove_pattern("${CMSIS_${FAMILY}_PATH}/include/ch32${FAMILY_L}0x.h" "#include \"ch32${FAMILY_L}0x_conf.h\"")

    list(APPEND CMSIS_INCLUDE_DIRS "${CMSIS_${FAMILY}_CORE_PATH}" "${CMSIS_${FAMILY}_PATH}/include")

    if(NOT (TARGET CMSIS::CH32::${FAMILY}))
        message(TRACE "FindCMSIS: creating library CMSIS::CH32::${FAMILY}")
        add_library(CMSIS::CH32::${FAMILY} INTERFACE IMPORTED)
        #CH32::${FAMILY} contains compile options and is define in <family>.cmake
        target_link_libraries(CMSIS::CH32::${FAMILY} INTERFACE CH32::${FAMILY})
        target_include_directories(CMSIS::CH32::${FAMILY} INTERFACE "${CMSIS_${FAMILY}_CORE_PATH}")
        target_include_directories(CMSIS::CH32::${FAMILY} INTERFACE "${CMSIS_${FAMILY}_PATH}/include")
    endif()

    # search for system_ch32[XX]0x.c
    find_file(CMSIS_${FAMILY}_SYSTEM
        NAMES system_ch32${FAMILY_L}0x.c
        PATHS "${CMSIS_${FAMILY}_PATH}/src/"
        NO_DEFAULT_PATH
    )
    list(APPEND CMSIS_SOURCES "${CMSIS_${FAMILY}_SYSTEM}")
    
    if(NOT CMSIS_${FAMILY}_SYSTEM)
        message(VERBOSE "FindCMSIS: system_ch32${FAMILY_L}xx.c for ${FAMILY} has not been found")
        continue()
    endif()

    # Fix v00x system ClockInit function
    file_replace("${CMSIS_${FAMILY}_SYSTEM}" "RCC_APB2Periph_GPIOD" "RCC_IOPDEN")
    
    set(WCH_DEVICES_FOUND TRUE)
    foreach(DEVICE ${WCH_DEVICES})
        message(TRACE "FindCMSIS: Iterating DEVICE ${DEVICE}")
                
        ch32_get_chip_type(${FAMILY} ${DEVICE} TYPE)
        string(TOLOWER ${DEVICE} DEVICE_L)
        string(TOLOWER ${TYPE} TYPE_L)
        
        get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
        if(NOT "ASM" IN_LIST languages)
            message(STATUS "FindCMSIS: Not generating target for startup file and linker script because ASM language is not enabled")
            continue()
        endif()
        
        find_file(CMSIS_${FAMILY}_${TYPE}_STARTUP
            NAMES startup_ch32${TYPE_L}.s
            PATHS "${CMSIS_${FAMILY}_PATH}/src"
            NO_DEFAULT_PATH
        )
        list(APPEND CMSIS_SOURCES "${CMSIS_${FAMILY}_${TYPE}_STARTUP}")
        if(NOT CMSIS_${FAMILY}_${TYPE}_STARTUP)
            set(WCH_DEVICES_FOUND FALSE)
            message("FindCMSIS: did not find file: startup_ch32${TYPE_L}.s or startup_ch32${TYPE_L}.s")
            break()
        endif()
        
        if(NOT (TARGET CMSIS::CH32::${TYPE}))
            message(TRACE "FindCMSIS: creating library CMSIS::CH32::${TYPE}")
            add_library(CMSIS::CH32::${TYPE} INTERFACE IMPORTED)
            target_link_libraries(CMSIS::CH32::${TYPE} INTERFACE CMSIS::CH32::${FAMILY} CH32::${TYPE})
            target_sources(CMSIS::CH32::${TYPE} INTERFACE "${CMSIS_${FAMILY}_${TYPE}_STARTUP}")
            target_sources(CMSIS::CH32::${TYPE} INTERFACE "${CMSIS_${FAMILY}_SYSTEM}")
        endif()
        
        add_library(CMSIS::CH32::${DEVICE} INTERFACE IMPORTED)
        target_link_libraries(CMSIS::CH32::${DEVICE} INTERFACE CMSIS::CH32::${TYPE})
        cmsis_generate_default_linker_script(${FAMILY} ${DEVICE})
    endforeach()

    if(WCH_DEVICES_FOUND)
       set(CMSIS_${COMP}_FOUND TRUE)
       message(DEBUG "CMSIS_${COMP}_FOUND TRUE")
    else()
       set(CMSIS_${COMP}_FOUND FALSE)
       message(DEBUG "CMSIS_${COMP}_FOUND FALSE")
    endif()

    list(REMOVE_DUPLICATES CMSIS_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES CMSIS_SOURCES)
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CMSIS
    REQUIRED_VARS CMSIS_INCLUDE_DIRS CMSIS_SOURCES
    FOUND_VAR CMSIS_FOUND
    HANDLE_COMPONENTS
)
