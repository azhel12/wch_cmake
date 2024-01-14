# This function gets a list of spl_driver using a given prefix and suffix
#
# out_list_spl_drivers   list of spl_drivers found
# spl_drivers_path       path to the spl's drivers
function(get_list_spl_drivers out_list_spl_drivers spl_drivers_path)
    #The pattern to retrieve a driver from a file name depends on the spl_driver_type field
    set(file_pattern ".+_([a-z0-9]+)\\.c$")

    #Retrieving all the .c files from spl_drivers_path
    file(GLOB filtered_files
        RELATIVE "${spl_drivers_path}/src"
        "${spl_drivers_path}/src/*.c")

    # For all matched .c files keep only those with a driver name pattern (e.g. ch32v00x_adc.c)
    list(FILTER filtered_files INCLUDE REGEX ${file_pattern})
    # From the files names keep only the driver type part using the regex (ch32v00x_(adc).c => catches rcc)
    list(TRANSFORM filtered_files REPLACE ${file_pattern} "\\1")
    #Making a return by reference by seting the output variable to PARENT_SCOPE
    set(${out_list_spl_drivers} ${filtered_files} PARENT_SCOPE)
endfunction()

################################################################################
# Checking the parameters provided to the find_package(SPL ...) call
# The expected parameters are families and or drivers in *any orders*
# Families are valid if on the list of known families.
# Drivers are valid if on the list of valid driver of any family. For this
# reason the requested families must be processed in two steps
#  - Step 1 : Checking all the requested families
#  - Step 2 : Generating all the valid drivers from requested families
#  - Step 3 : Checking the other requested components (Expected to be drivers)
################################################################################
# Step 1 : Checking all the requested families
foreach(COMP ${SPL_FIND_COMPONENTS})
    string(TOUPPER ${COMP} COMP_U)
    string(REGEX MATCH "^CH32([VLX]P?[0-9])([0-9][0-9][A-Z][0-9A-Z])?.*$" COMP_U ${COMP_U})
    if(CMAKE_MATCH_1) #Matches the family part of the provided CH32<FAMILY>[..] component
        list(APPEND SPL_FIND_COMPONENTS_FAMILIES ${COMP})
        message(TRACE "FindSPL: append COMP ${COMP} to SPL_FIND_COMPONENTS_FAMILIES")
    else()
        list(APPEND SPL_FIND_COMPONENTS_UNHANDLED ${COMP})
    endif()
endforeach()

# If no family requested look for all families
if(NOT SPL_FIND_COMPONENTS_FAMILIES)
    set(SPL_FIND_COMPONENTS_FAMILIES ${CH32_SUPPORTED_FAMILIES_LONG_NAME})
endif()

# Step 2 : Generating all the valid drivers from requested families
foreach(family_comp ${SPL_FIND_COMPONENTS_FAMILIES})
    string(TOUPPER ${family_comp} family_comp)
    string(REGEX MATCH "^CH32([VLX]P?[0-9])([0-9][0-9][A-Z][0-9A-Z])?.*$" family_comp ${family_comp})
    if(CMAKE_MATCH_1) #Matches the family part of the provided CH32<FAMILY>[..] component
        set(FAMILY ${CMAKE_MATCH_1})
        string(TOLOWER ${FAMILY} FAMILY_L)
    endif()

    find_path(SPL_${FAMILY}_PATH
        NAMES include/ch32${FAMILY_L}0x_rcc.h
        PATHS "${CH32_SPL_${FAMILY}_PATH}"
        NO_DEFAULT_PATH
        )
    if(NOT SPL_${FAMILY}_PATH)
        message(FATAL_ERROR "could not find SPL for family ${FAMILY}")
    else()
        set(SPL_${family_comp}_FOUND TRUE)
    endif()

    if(CMAKE_MATCH_1) #Matches the family part of the provided CH32<FAMILY>[..] component
        get_list_spl_drivers(SPL_DRIVERS_${FAMILY} ${SPL_${FAMILY}_PATH})
        list(APPEND SPL_DRIVERS ${SPL_DRIVERS_${FAMILY}})
    endif()
endforeach()
list(REMOVE_DUPLICATES SPL_DRIVERS)
list(REMOVE_DUPLICATES SPL_LL_DRIVERS)

# Step 3 : Checking the other requested components (Expected to be drivers)
foreach(COMP ${SPL_FIND_COMPONENTS_UNHANDLED})
    string(TOLOWER ${COMP} COMP_L)
    
    if(${COMP_L} IN_LIST SPL_DRIVERS)
        list(APPEND SPL_FIND_COMPONENTS_DRIVERS ${COMP})
        message(TRACE "FindSPL: append COMP ${COMP} to SPL_FIND_COMPONENTS_DRIVERS")
        continue()
    endif()

    message(FATAL_ERROR "FindSPL: unknown SPL component: ${COMP}")
endforeach()

list(REMOVE_DUPLICATES SPL_FIND_COMPONENTS_FAMILIES)

# when no explicit driver and driver_ll is given to find_component(SPL )
# then search for all supported driver and driver_ll
if(NOT SPL_FIND_COMPONENTS_DRIVERS)
    set(SPL_FIND_COMPONENTS_DRIVERS ${SPL_DRIVERS})
endif()
list(REMOVE_DUPLICATES SPL_FIND_COMPONENTS_DRIVERS)

message(STATUS "Search for SPL families: ${SPL_FIND_COMPONENTS_FAMILIES}")
message(STATUS "Search for SPL drivers: ${SPL_FIND_COMPONENTS_DRIVERS}")

foreach(COMP ${SPL_FIND_COMPONENTS_FAMILIES})
    string(TOUPPER ${COMP} COMP_U)
    
    string(REGEX MATCH "^CH32([VLX]P?[0-9])([0-9][0-9][A-Z][0-9A-Z])?.*$" COMP_U ${COMP_U})    
        
    set(FAMILY ${CMAKE_MATCH_1})
    string(TOLOWER ${FAMILY} FAMILY_L)

    find_path(SPL_${FAMILY}_PATH
        NAMES include/ch32${FAMILY_L}0x_rcc.h
        PATHS "${CH32_SPL_${FAMILY}_PATH}"
        NO_DEFAULT_PATH
    )
    if (NOT SPL_${FAMILY}_PATH)
        message(DEBUG "Missing SPL_${FAMILY}_PATH path")
        continue()
    endif()
    
    find_path(SPL_${FAMILY}_INCLUDE
        NAMES ch32${FAMILY_L}0x_rcc.h
        PATHS "${SPL_${FAMILY}_PATH}/include"
        NO_DEFAULT_PATH
    )
    find_file(SPL_${FAMILY}_SOURCE
        NAMES ch32${FAMILY_L}0x_rcc.c
        PATHS "${SPL_${FAMILY}_PATH}/src"
        NO_DEFAULT_PATH
    )
    
    if ((NOT SPL_${FAMILY}_INCLUDE) OR (NOT SPL_${FAMILY}_SOURCE))
        set(SPL_${COMP}_FOUND FALSE)
        message(DEBUG "FindSPL: did not find path to SPL /src or /include dir")
        continue()
    endif()

    if(NOT (TARGET SPL::CH32::${FAMILY}))
        message(TRACE "FindSPL: creating library SPL::CH32::${FAMILY}")
        add_library(SPL::CH32::${FAMILY} INTERFACE IMPORTED)
        target_link_libraries(SPL::CH32::${FAMILY} INTERFACE 
                                                    CH32::${FAMILY} 
                                                    CMSIS::CH32::${FAMILY})
        target_include_directories(SPL::CH32::${FAMILY} INTERFACE "${SPL_${FAMILY}_INCLUDE}")
        target_sources(SPL::CH32::${FAMILY} INTERFACE "${SPL_${FAMILY}_SOURCE}")
    endif()
    
    foreach(DRV_COMP ${SPL_FIND_COMPONENTS_DRIVERS})
        string(TOLOWER ${DRV_COMP} DRV_L)
        string(TOUPPER ${DRV_COMP} DRV)
        
        if(NOT (DRV_L IN_LIST SPL_DRIVERS_${FAMILY}))
            continue()
        endif()
        
        find_file(SPL_${FAMILY}_${DRV}_SOURCE
            NAMES ch32${FAMILY_L}0x_${DRV_L}.c
            PATHS "${SPL_${FAMILY}_PATH}/src"
            NO_DEFAULT_PATH
        )
        list(APPEND SPL_${FAMILY}_SOURCES "${SPL_${FAMILY}_${DRV}_SOURCE}")
        if(NOT SPL_${FAMILY}_${DRV}_SOURCE)
            message(WARNING "Cannot find ${DRV} driver for ${FAMILY}")
            set(SPL_${DRV_COMP}_FOUND FALSE)
            continue()
        endif()
                
        set(SPL_${DRV_COMP}_FOUND TRUE)
        if(SPL_${FAMILY}_${DRV}_SOURCE AND (NOT (TARGET SPL::CH32::${FAMILY}::${DRV})))
            message(TRACE "FindSPL: creating library SPL::CH32::${FAMILY}::${DRV}")
            add_library(SPL::CH32::${FAMILY}::${DRV} INTERFACE IMPORTED)
            target_link_libraries(SPL::CH32::${FAMILY}::${DRV} INTERFACE SPL::CH32::${FAMILY})
            target_sources(SPL::CH32::${FAMILY}::${DRV} INTERFACE "${SPL_${FAMILY}_${DRV}_SOURCE}")
        endif()
    endforeach()
    
    set(SPL_${COMP}_FOUND TRUE)
    list(APPEND SPL_INCLUDE_DIRS "${SPL_${FAMILY}_INCLUDE}")
    list(APPEND SPL_SOURCES "${SPL_${FAMILY}_SOURCES}")
endforeach()

list(REMOVE_DUPLICATES SPL_INCLUDE_DIRS)
list(REMOVE_DUPLICATES SPL_SOURCES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SPL
    REQUIRED_VARS SPL_INCLUDE_DIRS SPL_SOURCES
    FOUND_VAR SPL_FOUND
    HANDLE_COMPONENTS
)
