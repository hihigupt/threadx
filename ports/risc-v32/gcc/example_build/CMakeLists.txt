# Copyright (c) Microsoft Corporation. All rights reserved.
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.13)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/riscv_gcc.cmake)

project(sample_threadx C ASM)

set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -march=rv32imaf -mabi=ilp32" CACHE INTERNAL "c compiler flags")
set(TX_COMMON ${CMAKE_CURRENT_LIST_DIR}/../../../../common)

file(GLOB TX_SRC ${TX_COMMON}/src/*.c)
file(GLOB TX_PORT_SRC ${CMAKE_CURRENT_LIST_DIR}/../src/*.S)

add_library(tx.a ${TX_SRC}
    ${CMAKE_CURRENT_LIST_DIR}/../../../../utility/execution_profile_kit/tx_execution_profile.c
    ${TX_PORT_SRC}
)

target_include_directories(tx.a PUBLIC 
    ${TX_COMMON}/inc
    ${CMAKE_CURRENT_LIST_DIR}/../inc
    ./../../../../utility/execution_profile_kit/
)

add_executable(${PROJECT_NAME}
    ${CMAKE_CURRENT_LIST_DIR}/entry.S
    ${CMAKE_CURRENT_LIST_DIR}/sample_threadx.c)
add_compile_definitions(TX_ENABLE_EVENT_TRACE)
target_link_options(${PROJECT_NAME} PRIVATE
    -nostartfiles --specs=nano.specs -T ${CMAKE_CURRENT_LIST_DIR}/sample_threadx.ld)

target_link_libraries(${PROJECT_NAME} PRIVATE tx.a)
