cmake_minimum_required (VERSION 3.1)

project (aws-checksums C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/aws-checksums/cmake")
include(AwsSharedLibSetup)

file(GLOB AWS_CHECKSUMS_HEADERS
     "aws-checksums/include/aws/checksums/*.h"
)
list(FILTER AWS_CHECKSUMS_HEADERS EXCLUDE REGEX ".*jni.*")

file(GLOB AWS_CHECKSUMS_PRIV_HEADERS
     "aws-checksums/include/aws/checksums/private/*.h"
)

file(GLOB AWS_CHECKSUMS_SRC
    "aws-checksums/source/*.c"
)
list(FILTER AWS_CHECKSUMS_SRC EXCLUDE REGEX ".*jni.*")

file(GLOB AWS_ARCH_SRC
    "aws-checksums/source/intel/*.c"
    "aws-checksums/source/arm/*.c"
)

file(GLOB CHECKSUMS_HEADERS
    ${AWS_CHECKSUMS_HEADERS}
    ${AWS_CHECKSUMS_PRIV_HEADERS}
)

file(GLOB CHECKSUMS_SRC
  ${AWS_CHECKSUMS_SRC}
    ${AWS_CHECKSUMS_PLATFORM_SOURCE}
    ${AWS_ARCH_SRC}
)

add_library(aws-checksums SHARED ${CHECKSUMS_HEADERS} ${CHECKSUMS_SRC})
target_compile_options(aws-checksums PRIVATE ${_FLAGS})
set_target_properties(aws-checksums PROPERTIES LINKER_LANGUAGE C)
set(CMAKE_C_FLAGS_DEBUGOPT "")
set_property(TARGET aws-checksums PROPERTY C_STANDARD 99)

target_compile_options(aws-checksums PRIVATE -fPIC -O2)

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/aws-checksums/include>
    $<INSTALL_INTERFACE:include>)

target_link_libraries(aws-checksums ${PLATFORM_LIBS})

set(LIBRARY_DIRECTORY lib)
# Set the default lib installation path on GNU systems with GNUInstallDirs
if (UNIX AND NOT APPLE)
    include(GNUInstallDirs)
    set(LIBRARY_DIRECTORY ${CMAKE_INSTALL_LIBDIR})
endif()

aws_prepare_shared_lib_exports(${CMAKE_PROJECT_NAME})

if (BUILD_SHARED_LIBS)
   set (TARGET_DIR "shared")
else()
   set (TARGET_DIR "static")
endif()

