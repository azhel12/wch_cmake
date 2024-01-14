cmake_minimum_required(VERSION 3.16)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/wch_gcc.cmake)

project(cmsis_blink CXX C ASM)

ch32_fetch_cmsis(V0)
ch32_fetch_cmsis(V2)

find_package(CMSIS COMPONENTS CH32V0 CH32V2 REQUIRED)

set(PROJECT_SOURCES
    src/main.c)

add_executable(cmsis_blink ${PROJECT_SOURCES})
add_executable(cmsis_blink_203 ${PROJECT_SOURCES})

target_link_libraries(cmsis_blink CMSIS::CH32::V003F4 CH32::Nano CH32::NoSys)
target_link_libraries(cmsis_blink_203 CMSIS::CH32::V203C8 CH32::Nano CH32::NoSys)

ch32_print_size_of_target(cmsis_blink)
ch32_print_size_of_target(cmsis_blink_203)

ch32_generate_hex_file(cmsis_blink)
ch32_generate_hex_file(cmsis_blink_203)