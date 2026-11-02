cmake_minimum_required(VERSION 3.16)

# Set the project name
project(declutter VERSION 1.0 LANGUAGES CXX)

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Custom build types, in addition to CMake's Debug, Release, RelWithDebInfo
# and MinSizeRel. Each one's flags are defined once, via the per-config
# CMAKE_<LANG>_FLAGS_<TYPE> variables, which work for both single-config
# generators (CMAKE_BUILD_TYPE) and multi-config ones (Visual Studio, Xcode).
set(DCL_CUSTOM_BUILD_TYPES ASAN UBSAN TSAN MSAN COVERAGE)

if (MSVC)
    # MSVC has AddressSanitizer only; it has no UBSan, TSan or MSan, and
    # coverage needs external tooling.
    set(DCL_SUPPORTED_BUILD_TYPES ASAN)
    set(CMAKE_CXX_FLAGS_ASAN "/fsanitize=address /Zi")
    set(CMAKE_EXE_LINKER_FLAGS_ASAN "/DEBUG")
else()
    set(DCL_SUPPORTED_BUILD_TYPES ASAN UBSAN TSAN COVERAGE)

    set(CMAKE_CXX_FLAGS_ASAN "-fsanitize=address -fno-omit-frame-pointer -g")
    set(CMAKE_EXE_LINKER_FLAGS_ASAN "-fsanitize=address")

    set(CMAKE_CXX_FLAGS_UBSAN "-fsanitize=undefined -fno-sanitize-recover=all -g")
    set(CMAKE_EXE_LINKER_FLAGS_UBSAN "-fsanitize=undefined")

    set(CMAKE_CXX_FLAGS_TSAN "-fsanitize=thread -g")
    set(CMAKE_EXE_LINKER_FLAGS_TSAN "-fsanitize=thread")

    set(CMAKE_CXX_FLAGS_COVERAGE "--coverage -O0 -g")
    set(CMAKE_EXE_LINKER_FLAGS_COVERAGE "--coverage")

    # MemorySanitizer exists only in Clang on Linux, and needs an
    # instrumented libc++ to avoid false positives.
    if (CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        list(APPEND DCL_SUPPORTED_BUILD_TYPES MSAN)
        set(CMAKE_CXX_FLAGS_MSAN
            "-fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer -g")
        set(CMAKE_EXE_LINKER_FLAGS_MSAN "-fsanitize=memory")
    endif()
endif()

# Reject an explicitly requested unsupported type with any generator; the
# run-builds scripts pass CMAKE_BUILD_TYPE even to multi-config generators
# and look for the "Unsupported build type" prefix to report a skip.
if (CMAKE_BUILD_TYPE)
    string(TOUPPER "${CMAKE_BUILD_TYPE}" build_type)
    if (build_type IN_LIST DCL_CUSTOM_BUILD_TYPES AND
        NOT build_type IN_LIST DCL_SUPPORTED_BUILD_TYPES)
        message(FATAL_ERROR
            "Unsupported build type: ${CMAKE_BUILD_TYPE} is not supported "
            "with ${CMAKE_CXX_COMPILER_ID} on ${CMAKE_SYSTEM_NAME}. "
            "Supported custom build types: ${DCL_SUPPORTED_BUILD_TYPES}")
    endif()
endif()

get_property(is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if (is_multi_config)
    # Offer the supported custom types alongside the generator's defaults.
    foreach (build_type IN LISTS DCL_SUPPORTED_BUILD_TYPES)
        if (NOT build_type IN_LIST CMAKE_CONFIGURATION_TYPES)
            list(APPEND CMAKE_CONFIGURATION_TYPES ${build_type})
        endif()
    endforeach()
endif()

# Add the executable
add_executable(dcl main.cc)
target_compile_definitions(dcl PRIVATE "DCL_VERSION=\"${PROJECT_VERSION}\"")

# `cmake --install build` puts dcl in <prefix>/bin
install(TARGETS dcl)

if (MSVC)
    target_compile_options(dcl PRIVATE /W4)
else()
    target_compile_options(dcl PRIVATE -Wall -Wextra -pedantic)
endif()

# Tests
enable_testing()
foreach (case grouping ignore_case hidden trailing_dot empty_dir symlinks double_dash
              dash_path_without_separator empty_arg missing_path
              not_a_directory unknown_option extra_argument help version)
    add_test(NAME dcl_${case}
        COMMAND ${CMAKE_COMMAND}
            -DDCL=$<TARGET_FILE:dcl>
            -DCASE=${case}
            -DDCL_VERSION=${PROJECT_VERSION}
            -DWORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/test-fixtures
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/dcl_test.cmake)
    # Cases print "SKIPPED:" when the platform can't build their fixture,
    # e.g. symlinks without privileges, or "foo." on Windows.
    set_tests_properties(dcl_${case} PROPERTIES SKIP_REGULAR_EXPRESSION "SKIPPED:")
endforeach()

# On macOS, build a universal binary unless the user chose architectures.
if (APPLE AND NOT CMAKE_OSX_ARCHITECTURES)
    set_target_properties(dcl PROPERTIES
        OSX_ARCHITECTURES "x86_64;arm64"
    )
endif()
