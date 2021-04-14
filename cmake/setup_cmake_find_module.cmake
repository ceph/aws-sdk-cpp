# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0.


add_project(AWSSDK "User friendly cmake creator")

# create a new version file for AWSSDK, then find_package will return latest PACKAGE_VERSION
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}ConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

file(APPEND
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}ConfigVersion.cmake"
    "set(AWSSDK_INSTALL_AS_SHARED_LIBS ${BUILD_SHARED_LIBS})\n")

file(WRITE
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/platformDeps.cmake"
"# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0.\n"
    "set(AWSSDK_PLATFORM_DEPS_LIBS ${PLATFORM_DEP_LIBS_ABSTRACT_NAME})\n"
    "set(AWSSDK_CLIENT_LIBS ${CLIENT_LIBS_ABSTRACT_NAME})\n"
    "set(AWSSDK_CRYPTO_LIBS ${CRYPTO_LIBS_ABSTRACT_NAME})\n"
    "set(AWSSDK_THIRD_PARTY_LIBS ${THIRD_PARTY_LIBS})\n"
    "set(AWSSDK_ADDITIONAL_LIBS ${AWS_SDK_ADDITIONAL_LIBRARIES_ABSTRACT_NAME})\n"
    "set(AWSSDK_INSTALL_LIBDIR ${LIBRARY_DIRECTORY})\n"
    "set(AWSSDK_INSTALL_BINDIR ${BINARY_DIRECTORY})\n"
    "set(AWSSDK_INSTALL_INCLUDEDIR ${INCLUDE_DIRECTORY})\n"
    "set(AWSSDK_INSTALL_ARCHIVEDIR ${ARCHIVE_DIRECTORY})\n"
    )

if (NOT SIMPLE_INSTALL)
    file(APPEND
        "${CMAKE_CURRENT_BINARY_DIR}/platformDeps.cmake"
        "set(AWSSDK_PLATFORM_PREFIX ${SDK_INSTALL_BINARY_PREFIX}/${PLATFORM_INSTALL_QUALIFIER})\n")
endif()

