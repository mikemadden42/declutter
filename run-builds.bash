#!/bin/bash

set -euo pipefail

# List of build types
BUILD_TYPES=("Debug" "Release" "ASAN" "UBSAN" "TSAN" "MSAN" "COVERAGE" "RelWithDebInfo")

# Directory for the build
BUILD_DIR="build"

# CMake starts its error with this when the platform can't build a type
UNSUPPORTED_MARKER="Unsupported build type"

# Initialize counters and arrays for build results
success_count=0
failure_count=0
skipped_count=0
successful_builds=()
failed_builds=()
skipped_builds=()

# Loop through each build type
for build_type in "${BUILD_TYPES[@]}"; do
	echo "Building for type: $build_type"

	# Remove any existing build artifacts
	rm -rf "$BUILD_DIR"

	# Configure, keeping the output to check why it failed
	configure_status=0
	configure_output=$(cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$build_type" 2>&1) ||
		configure_status=$?
	echo "$configure_output"

	if [ "$configure_status" -ne 0 ]; then
		if grep -q "$UNSUPPORTED_MARKER" <<<"$configure_output"; then
			echo "$build_type is not supported on this platform; skipped."
			skipped_builds+=("$build_type")
			skipped_count=$((skipped_count + 1))
		else
			echo "CMake configuration for $build_type failed."
			failed_builds+=("$build_type")
			failure_count=$((failure_count + 1))
		fi
	elif cmake --build "$BUILD_DIR" --config "$build_type"; then
		echo "$build_type build succeeded."
		successful_builds+=("$build_type")
		success_count=$((success_count + 1))
	else
		echo "$build_type build failed."
		failed_builds+=("$build_type")
		failure_count=$((failure_count + 1))
	fi
done

# Report the summary of builds
echo "Build Summary:"
echo "Successful Builds: $success_count"
echo "Failed Builds: $failure_count"
echo "Skipped Builds: $skipped_count"

# List successful build types
if [ ${#successful_builds[@]} -gt 0 ]; then
	echo "Successful Build Types:"
	for successful_build in "${successful_builds[@]}"; do
		echo "  - $successful_build"
	done
fi

# List failed build types if there were any failures
if [ ${#failed_builds[@]} -gt 0 ]; then
	echo "Failed Build Types:"
	for failed_build in "${failed_builds[@]}"; do
		echo "  - $failed_build"
	done
fi

# List build types this platform can't build
if [ ${#skipped_builds[@]} -gt 0 ]; then
	echo "Skipped Build Types (unsupported on this platform):"
	for skipped_build in "${skipped_builds[@]}"; do
		echo "  - $skipped_build"
	done
fi

# Exit with appropriate status code; skipped builds are not failures
if [ "$failure_count" -gt 0 ]; then
	exit 1
else
	exit 0
fi
