set(CH32_ALL_DEVICES
    V003J4
    V003A4
    V003F4
    V103C6
    V103C8
    V103R8
    V203F6
    V203F8
    V203G6
    V203G8
    V203K6
    V203K8
    V203C6
    V203C8
    V203RB
)

# Store a list of devices into a given WCH_DEVICES list.
# You can also specify multiple device families. Examples:
# Get list of all devices for V0 family: ch32_get_devices_by_family(WCH_DEVICES FAMILY V0)
# Get list of all devices: ch32_get_devices_by_family(WCH_DEVICES)
function(ch32_get_devices_by_family WCH_DEVICES)
    # Specify keywords for argument parsing here
    set(ARG_OPTIONS "")
    set(ARG_SINGLE "")
    set(ARG_MULTIPLE FAMILY)

    # Parse arguments. Multiple families can be specified and will be stored in ARG_<KeywordName>
    cmake_parse_arguments(PARSE_ARGV 1 ARG "${ARG_OPTIONS}" "${ARG_SINGLE}" "${ARG_MULTIPLE}")
    ch32_dev_parser_check()

    # Build a list of families by filtering the whole list with the specified families
    if(ARG_FAMILY)
        set(RESULTING_DEV_LIST "")
        foreach(FAMILY ${ARG_FAMILY})
            set(WCH_DEVICE_LIST ${CH32_ALL_DEVICES})
            list(FILTER WCH_DEVICE_LIST INCLUDE REGEX "^${FAMILY}")
            list(APPEND RESULTING_DEV_LIST ${WCH_DEVICE_LIST})
            if(NOT WCH_DEVICE_LIST)
                message(WARNING "No devices found for given family ${FAMILY}")
            endif()
        endforeach()
    else()
        # No family argument, so get list of all devices
        set(RESULTING_DEV_LIST ${CH32_ALL_DEVICES})
    endif()

    set(${WCH_DEVICES} ${RESULTING_DEV_LIST} PARENT_SCOPE)
endfunction()

# Print the devices for a given family. You can also specify multiple device families.
# Example usage:
# Print devices for V0 family: ch32_print_devices_by_family(FAMILY V0)
# Print all devices: ch32_print_devices_by_family()
function(ch32_print_devices_by_family)
    # Specify keywords for argument parsing here
    set(ARG_OPTIONS "")
    set(ARG_SINGLE "")
    set(ARG_MULTIPLE FAMILY)

    # Parse arguments. Multiple families can be specified and will be stored in ARG_<KeywordName>
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${ARG_OPTIONS}" "${ARG_SINGLE}" "${ARG_MULTIPLE}")
    ch32_dev_parser_check()

    if(ARG_FAMILY)
        # print devices one family per line
        foreach(FAMILY ${ARG_FAMILY})
            ch32_get_devices_by_family(WCH_DEVICES FAMILY ${FAMILY})
            ch32_pretty_print_dev_list(${FAMILY} "${WCH_DEVICES}")
        endforeach()
    else()
        # print all devices
        ch32_get_devices_by_family(WCH_DEVICES)
        ch32_pretty_print_dev_list("all" "${WCH_DEVICES}")
    endif()

endfunction()

# The arguments checked in this macro are filled by cmake_parse_argument
macro(ch32_dev_parser_check)
    # contains unexpected arguments (unknown keywords beofre ARG_MULTIPLE)
    if(ARG_UNPARSED_ARGUMENTS)
        message(WARNING "Unknown keyword(s) ${ARG_UNPARSED_ARGUMENTS} will be ignored")
    endif()
    # is populated if ARG_SINGLE or ARG_MULTIPLE is used without values
    if(ARG_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Keyword ${ARG_KEYWORDS_MISSING_VALUES} expects values")
    endif()
endmacro()

# Pretty printer to limit amount of list entries printed per line
macro(ch32_pretty_print_dev_list FAMILIES WCH_DEVICES)
    if(${FAMILIES} STREQUAL "all")
        message(STATUS  "Devices for all families")
    else()
        message(STATUS "Devices for ${FAMILIES} family")
    endif()
    set(TMP_LIST "")
    foreach(WCH_DEVICE ${WCH_DEVICES})
        list(APPEND TMP_LIST ${WCH_DEVICE})
        list(LENGTH TMP_LIST CURR_LEN)
        if(CURR_LEN EQUAL 10)
            message(STATUS "${TMP_LIST}")
            set(TMP_LIST "")
        endif()
    endforeach()
    if(TMP_LIST)
        message(STATUS "${TMP_LIST}")
   endif()
endmacro()
