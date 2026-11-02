@echo off
setlocal enabledelayedexpansion

:: List of build types
set BUILD_TYPES=Debug Release ASAN UBSAN TSAN MSAN COVERAGE RelWithDebInfo

:: Directory for the build
set BUILD_DIR=build

:: CMake starts its error with this when the platform can't build a type
set "UNSUPPORTED_MARKER=Unsupported build type"

:: Configure output is kept here to check why a configure failed
set "CONFIGURE_LOG=%TEMP%\declutter-configure.log"

:: Initialize counters and lists for build results
set /a success_count=0
set /a failure_count=0
set /a skipped_count=0
set "successful_builds="
set "failed_builds="
set "skipped_builds="

:: Loop through each build type.
:: Inside this block, use "rem" rather than "::" for comments, and
:: "if errorlevel 1" rather than %errorlevel%, which would be expanded
:: once when the block is parsed instead of after each command runs.
for %%B in (%BUILD_TYPES%) do (
    echo Building for type: %%B

    rem Remove any existing build artifacts
    if exist %BUILD_DIR% rd /s /q %BUILD_DIR%

    rem Run CMake with the current build type, keeping its output
    cmake -S . -B %BUILD_DIR% -DCMAKE_BUILD_TYPE=%%B > "%CONFIGURE_LOG%" 2>&1
    if errorlevel 1 (set "configure_failed=1") else (set "configure_failed=0")
    type "%CONFIGURE_LOG%"

    if "!configure_failed!"=="1" (
        findstr /c:"%UNSUPPORTED_MARKER%" "%CONFIGURE_LOG%" >nul
        if errorlevel 1 (
            echo CMake configuration for %%B failed.
            set "failed_builds=!failed_builds! %%B"
            set /a failure_count+=1
        ) else (
            echo %%B is not supported on this platform; skipped.
            set "skipped_builds=!skipped_builds! %%B"
            set /a skipped_count+=1
        )
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

if exist "%CONFIGURE_LOG%" del "%CONFIGURE_LOG%"

:: Report the summary of builds
echo Build Summary:
echo Successful Builds: %success_count%
echo Failed Builds: %failure_count%
echo Skipped Builds: %skipped_count%

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

:: List build types this platform can't build
if not "!skipped_builds!"=="" (
    echo Skipped Build Types ^(unsupported on this platform^):
    for %%K in (%skipped_builds%) do echo   - %%K
)

:: Exit with appropriate status code; skipped builds are not failures
if %failure_count% gtr 0 (
    exit /b 1
) else (
    exit /b 0
)
