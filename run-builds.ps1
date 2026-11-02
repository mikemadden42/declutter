# List of build types
$buildTypes = @("Debug", "Release", "ASAN", "UBSAN", "TSAN", "MSAN", "COVERAGE", "RelWithDebInfo")

# Directory for the build
$buildDir = "build"

# CMake starts its error with this when the platform can't build a type
$unsupportedMarker = "Unsupported build type"

# Initialize counters and lists for build results
$successCount = 0
$failureCount = 0
$skippedCount = 0
$successfulBuilds = @()
$failedBuilds = @()
$skippedBuilds = @()

# Loop through each build type
foreach ($buildType in $buildTypes) {
    Write-Output "Building for type: $buildType"

    # Remove any existing build artifacts
    if (Test-Path $buildDir) {
        Remove-Item -Recurse -Force $buildDir
    }

    # Run CMake with the current build type, keeping its output as text
    $configureOutput = cmake -S . -B $buildDir -DCMAKE_BUILD_TYPE=$buildType 2>&1 |
        ForEach-Object { "$_" }
    $configureExitCode = $LASTEXITCODE
    $configureOutput | Write-Output

    if ($configureExitCode -ne 0) {
        if (($configureOutput -join "`n") -match [regex]::Escape($unsupportedMarker)) {
            Write-Output "$buildType is not supported on this platform; skipped."
            $skippedBuilds += $buildType
            $skippedCount++
        } else {
            Write-Output "CMake configuration for $buildType failed."
            $failedBuilds += $buildType
            $failureCount++
        }
        continue
    }

    # Build the project, letting compiler output stream to the console
    cmake --build $buildDir --config $buildType
    if ($LASTEXITCODE -eq 0) {
        Write-Output "$buildType build succeeded."
        $successfulBuilds += $buildType
        $successCount++
    } else {
        Write-Output "$buildType build failed."
        $failedBuilds += $buildType
        $failureCount++
    }
}

# Report the summary of builds
Write-Output "Build Summary:"
Write-Output "Successful Builds: $successCount"
Write-Output "Failed Builds: $failureCount"
Write-Output "Skipped Builds: $skippedCount"

# List successful build types
if ($successfulBuilds.Count -gt 0) {
    Write-Output "Successful Build Types:"
    foreach ($successfulBuild in $successfulBuilds) {
        Write-Output "  - $successfulBuild"
    }
}

# List failed build types
if ($failedBuilds.Count -gt 0) {
    Write-Output "Failed Build Types:"
    foreach ($failedBuild in $failedBuilds) {
        Write-Output "  - $failedBuild"
    }
}

# List build types this platform can't build
if ($skippedBuilds.Count -gt 0) {
    Write-Output "Skipped Build Types (unsupported on this platform):"
    foreach ($skippedBuild in $skippedBuilds) {
        Write-Output "  - $skippedBuild"
    }
}

# Exit with appropriate status code; skipped builds are not failures
if ($failureCount -gt 0) {
    exit 1
} else {
    exit 0
}
