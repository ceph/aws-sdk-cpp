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
cmake_minimum_required (VERSION 3.1)
project (aws-c-event-stream C)

if (DEFINED CMAKE_PREFIX_PATH)
    file(TO_CMAKE_PATH "${CMAKE_PREFIX_PATH}" CMAKE_PREFIX_PATH)
endif()

if (DEFINED CMAKE_INSTALL_PREFIX)
    file(TO_CMAKE_PATH "${CMAKE_INSTALL_PREFIX}" CMAKE_INSTALL_PREFIX)
endif()

if (UNIX AND NOT APPLE)
    include(GNUInstallDirs)
elseif(NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "lib")
endif()

# This is required in order to append /lib/cmake to each element in CMAKE_PREFIX_PATH
set(AWS_MODULE_DIR "/${CMAKE_INSTALL_LIBDIR}/cmake")
string(REPLACE ";" "${AWS_MODULE_DIR};" AWS_MODULE_PATH "${CMAKE_PREFIX_PATH}${AWS_MODULE_DIR}")
# Append that generated list to the module search path
list(APPEND CMAKE_MODULE_PATH ${AWS_MODULE_PATH})

include(AwsCFlags)
include(AwsSharedLibSetup)
include(AwsSanitizers)
include(CheckCCompilerFlag)

if(NOT MSVC)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/aws-c-event-stream/lib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/aws-c-event-stream/lib)
endif()

file(GLOB AWS_EVENT_STREAM_HEADERS
     "aws-c-event-stream/include/aws/event-stream/*.h"
)

file(GLOB AWS_EVENT_STREAM_PRIV_HEADERS
     "aws-c-event-stream/include/aws/event-stream/private/*.h"
)

file(GLOB AWS_EVENT_STREAM_SRC
    "aws-c-event-stream/source/*.c"
)

file(GLOB EVENT_STREAM_HEADERS
    ${AWS_EVENT_STREAM_HEADERS}
)

file(GLOB EVENT_STREAM_SRC
    ${AWS_EVENT_STREAM_SRC}
)

add_library(${CMAKE_PROJECT_NAME} SHARED ${EVENT_STREAM_SRC})
aws_set_common_properties(${CMAKE_PROJECT_NAME})
aws_add_sanitizers(${CMAKE_PROJECT_NAME})
aws_prepare_symbol_visibility_args(${CMAKE_PROJECT_NAME} "AWS_EVENT_STREAM")

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/aws-c-event-stream/include>
    $<INSTALL_INTERFACE:include>)

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES VERSION 1.0.0)

target_link_libraries(${CMAKE_PROJECT_NAME} PUBLIC aws-c-common aws-checksums)

aws_prepare_shared_lib_exports(${CMAKE_PROJECT_NAME})

if (BUILD_SHARED_LIBS)
   set (TARGET_DIR "shared")
else()
   set (TARGET_DIR "static")
endif()

