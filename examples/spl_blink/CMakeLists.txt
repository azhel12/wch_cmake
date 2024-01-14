cmake_minimum_required(VERSION 3.16)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/wch_gcc.cmake)

project(spl_blink CXX C ASM)

ch32_fetch_cmsis(V0 V2)
ch32_fetch_spl(V0 V2)

find_package(CMSIS COMPONENTS CH32V0 CH32V2 REQUIRED)
find_package(SPL COMPONENTS CH32V0 CH32V2 RCC GPIO REQUIRED)

set(PROJECT_SOURCES
    src/main.c)

add_executable(spl_blink ${PROJECT_SOURCES})
add_executable(spl_blink_203 ${PROJECT_SOURCES})

target_link_libraries(spl_blink
    SPL::CH32::V0::GPIO
    SPL::CH32::V0::RCC
    CMSIS::CH32::V003F4
    CH32::NoSys)

target_link_libraries(spl_blink_203
    SPL::CH32::V2::GPIO
    SPL::CH32::V2::RCC
    CMSIS::CH32::V203C8
    CH32::NoSys)

ch32_print_size_of_target(spl_blink)
ch32_print_size_of_target(spl_blink_203)

ch32_generate_hex_file(spl_blink_203)