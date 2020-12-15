# Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#  http://aws.amazon.com/apache2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

cmake_minimum_required(VERSION 3.0)
option(ALLOW_CROSS_COMPILED_TESTS "Allow tests to be compiled via cross compile, for use with qemu" OFF)

project(aws-c-common LANGUAGES C VERSION 0.1.0)

if (POLICY CMP0069)
    cmake_policy(SET CMP0069 NEW) # Enable LTO/IPO if available in the compiler, see AwsCFlags
endif()

if (POLICY CMP0077)
    cmake_policy(SET CMP0077 OLD) # Enable options to get their values from normal variables
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/aws-c-common/cmake")
include(AwsCFlags)
include(AwsCheckHeaders)
include(AwsSharedLibSetup)
include(AwsFeatureTests)
include(AwsSanitizers)
include(AwsSIMD)

set(GENERATED_ROOT_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(GENERATED_INCLUDE_DIR "${GENERATED_ROOT_DIR}/aws-c-common/include/")
set(GENERATED_CONFIG_HEADER "${GENERATED_INCLUDE_DIR}/aws/common/config.h")
set(CONFIG_HEADER_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/aws-c-common/include/aws/common/config.h.in")

file(GLOB AWS_COMMON_HEADERS
        "aws-c-common/include/aws/common/*.h"
        "aws-c-common/include/aws/common/*.inl"
        )

file(GLOB AWS_TEST_HEADERS
        "aws-c-common/include/aws/testing/*.h"
        )

file(GLOB AWS_COMMON_PRIV_HEADERS
        "aws-c-common/include/aws/common/private/*.h"
        "aws-c-common/include/aws/common/private/*.c"
        )

file(GLOB AWS_COMMON_SRC
        "aws-c-common/source/*.c"
        )

option(AWS_NUM_CPU_CORES "Number of CPU cores of the target machine. Useful when cross-compiling." 0)

file(GLOB AWS_COMMON_OS_HEADERS
    "aws-c-common/include/aws/common/posix/*"
    )
file(GLOB AWS_COMMON_OS_SRC
    "aws-c-common/source/posix/*.c"
    )
set(THREADS_PREFER_PTHREAD_FLAG ON)

if (UNIX OR APPLE)
    find_package(Threads REQUIRED)
endif ()

if (APPLE)
    find_library(CORE_FOUNDATION_LIB CoreFoundation)
    if (NOT CORE_FOUNDATION_LIB)
        message(FATAL_ERROR "Core Foundation not found")
    endif ()
    list(APPEND PLATFORM_LIBS Threads::Threads ${CORE_FOUNDATION_LIB})
elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Linux") # Android does not link to libpthread nor librt, so this is fine
    list(APPEND PLATFORM_LIBS m Threads::Threads rt)
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    list(APPEND PLATFORM_LIBS m thr execinfo)
elseif(CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
    list(APPEND PLATFORM_LIBS m Threads::Threads execinfo)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android")
    list(APPEND PLATFORM_LIBS log)
    file(GLOB ANDROID_SRC "aws-c-common/source/android/*.c")
    list(APPEND AWS_COMMON_OS_SRC "${ANDROID_SRC}")
endif()

list(APPEND PLATFORM_LIBS ${CMAKE_DL_LIBS})

file(GLOB COMMON_HEADERS
        ${AWS_COMMON_HEADERS}
        ${AWS_COMMON_OS_HEADERS}
        ${AWS_COMMON_PRIV_HEADERS}
        ${AWS_TEST_HEADERS}
        )

file(GLOB COMMON_SRC
        ${AWS_COMMON_SRC}
        ${AWS_COMMON_OS_SRC}
        )

      add_library(${PROJECT_NAME} SHARED ${COMMON_SRC})
aws_set_common_properties(${PROJECT_NAME} NO_WEXTRA)
aws_prepare_symbol_visibility_args(${PROJECT_NAME} "AWS_COMMON")
target_compile_options(${PROJECT_NAME} PUBLIC ${PLATFORM_CFLAGS})

aws_check_headers(${PROJECT_NAME} ${AWS_COMMON_HEADERS} ${AWS_TEST_HEADERS} ${AWS_COMMON_OS_HEADERS})

#apple source already includes the definitions we want, and setting this posix source
#version causes it to revert to an older version. So don't turn it on there, we don't need it.
if (UNIX AND NOT APPLE AND NOT ${CMAKE_SYSTEM_NAME} MATCHES FreeBSD)
    #this only gets applied to aws-c-common (not its consumers).
    target_compile_definitions(${PROJECT_NAME} PRIVATE -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=500)
endif()

aws_add_sanitizers(${PROJECT_NAME} BLACKLIST "sanitizer-blacklist.txt")
target_link_libraries(${PROJECT_NAME} PUBLIC ${PLATFORM_LIBS})
target_compile_definitions(${PROJECT_NAME} PRIVATE ${PLATFORM_DEFINES})

if (AWS_NUM_CPU_CORES)
    target_compile_definitions(${PROJECT_NAME} PRIVATE -DAWS_NUM_CPU_CORES=${AWS_NUM_CPU_CORES})
endif()

# Our ABI is not yet stable
set_target_properties(${PROJECT_NAME} PROPERTIES VERSION 1.0.0)

target_include_directories(${PROJECT_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/aws-c-common/include>
        $<INSTALL_INTERFACE:include>)
# When we install, the generated header will be at the INSTALL_INTERFACE:include location,
# but at build time we need to explicitly include this here
target_include_directories(${PROJECT_NAME} PUBLIC
        $<BUILD_INTERFACE:${GENERATED_INCLUDE_DIR}>)

# Enable SIMD encoder if the compiler supports the right features
simd_add_definitions(${PROJECT_NAME})

if (HAVE_MAY_I_USE OR HAVE_BUILTIN_CPU_SUPPORTS OR HAVE_MSVC_CPUIDEX)
    set(HAVE_SIMD_CPUID TRUE)
endif()

if (HAVE_AVX2_INTRINSICS AND HAVE_SIMD_CPUID)
    target_compile_definitions(${PROJECT_NAME} PRIVATE -DUSE_SIMD_ENCODING)
    target_sources(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/aws-c-common/source/arch/cpuid.c")
    simd_add_source_avx2(${PROJECT_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/aws-c-common/source/arch/encoding_avx2.c")
    message(STATUS "Building SIMD base64 decoder")
endif()

aws_prepare_shared_lib_exports(${PROJECT_NAME})

if (BUILD_SHARED_LIBS)
   set (TARGET_DIR "shared")
else()
   set (TARGET_DIR "static")
endif()

# This should come last, to ensure all variables defined by cmake will be available for export
configure_file(${CONFIG_HEADER_TEMPLATE}
        ${GENERATED_CONFIG_HEADER}
        ESCAPE_QUOTES)

