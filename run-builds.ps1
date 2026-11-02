# List of build types
$buildTypes = @("Debug", "Release", "ASAN", "UBSAN", "TSAN", "MSAN", "COVERAGE", "RelWithDebInfo")

# Directory for the build
$buildDir = "build"

# Initialize counters and lists for build results
$successCount = 0
$failureCount = 0
$successfulBuilds = @()
$failedBuilds = @()

# Loop through each build type
foreach ($buildType in $buildTypes) {
    Write-Output "Building for type: $buildType"

    # Remove any existing build artifacts
    if (Test-Path $buildDir) {
        Remove-Item -Recurse -Force $buildDir
    }

    # Run CMake with the current build type
    cmake -S . -B $buildDir -DCMAKE_BUILD_TYPE=$buildType
    if ($LASTEXITCODE -ne 0) {
        Write-Output "CMake configuration for $buildType failed."
        $failedBuilds += $buildType
        $failureCount++
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

# Exit with appropriate status code
if ($failureCount -gt 0) {
    exit 1
} else {
    exit 0
}
