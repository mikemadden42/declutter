@echo off
setlocal enabledelayedexpansion

:: List of build types
set BUILD_TYPES=Debug Release ASAN UBSAN TSAN MSAN COVERAGE RelWithDebInfo

:: Directory for the build
set BUILD_DIR=build

:: Initialize counters and lists for build results
set /a success_count=0
set /a failure_count=0
set "successful_builds="
set "failed_builds="

:: Loop through each build type.
:: Inside this block, use "rem" rather than "::" for comments, and
:: "if errorlevel 1" rather than %errorlevel%, which would be expanded
:: once when the block is parsed instead of after each command runs.
for %%B in (%BUILD_TYPES%) do (
    echo Building for type: %%B

    rem Remove any existing build artifacts
    if exist %BUILD_DIR% rd /s /q %BUILD_DIR%

    rem Run CMake with the current build type
    cmake -S . -B %BUILD_DIR% -DCMAKE_BUILD_TYPE=%%B

    if errorlevel 1 (
        echo CMake configuration for %%B failed.
        set "failed_builds=!failed_builds! %%B"
        set /a failure_count+=1
    ) else (
        rem Build the project
        cmake --build %BUILD_DIR% --config %%B
        if errorlevel 1 (
            echo %%B build failed.
            set "failed_builds=!failed_builds! %%B"
            set /a failure_count+=1
        ) else (
            echo %%B build succeeded.
            set "successful_builds=!successful_builds! %%B"
            set /a success_count+=1
        )
    )
)

:: Report the summary of builds
echo Build Summary:
echo Successful Builds: %success_count%
echo Failed Builds: %failure_count%

:: List successful build types
if not "!successful_builds!"=="" (
    echo Successful Build Types:
    for %%S in (%successful_builds%) do echo   - %%S
)

:: List failed build types if there were any failures
if not "!failed_builds!"=="" (
    echo Failed Build Types:
    for %%F in (%failed_builds%) do echo   - %%F
)

:: Exit with appropriate status code
if %failure_count% gtr 0 (
    exit /b 1
) else (
    exit /b 0
)
