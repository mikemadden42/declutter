# Project TODOs

## Features
- [ ] **Command-line argument support**: Allow users to specify the directory path as an argument instead of defaulting to the current directory (`.`).
- [ ] **Hidden files option**: Add a flag to optionally include hidden files (those starting with a `.`) in the output.

## Robustness & Error Handling
- [ ] **Directory access handling**: Wrap directory iteration in `try-catch` blocks to handle `std::filesystem::filesystem_error` (e.g., permission denied, non-existent path).
- [ ] **Validation**: Ensure the provided path exists and is indeed a directory before processing.

## Build System (CMake)
- [ ] **Refactor redundant flags**: Consolidate global `CMAKE_CXX_FLAGS_<TYPE>` settings and the `add_custom_flags` function to follow DRY (Don't Repeat Yourself) principles.
- [ ] **Multi-config generator support**: Update the build logic to better support generators like Visual Studio and Xcode where `CMAKE_BUILD_TYPE` is not available at generation time.

## Quality Assurance
- [ ] **Automated Testing**: Implement a test suite to verify file grouping logic and error handling.
- [ ] **CI/CD**: Expand the GitHub Actions workflow to run tests across different platforms.
