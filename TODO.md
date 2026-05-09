# Project TODOs

## Features
- [x] **Command-line argument support**: Allow users to specify the directory path as an argument instead of defaulting to the current directory (`.`).
- [x] **Hidden files option**: Add a flag to optionally include hidden files (those starting with a `.`) in the output.

## Code Correctness (`main.cc`)
- [x] **Undefined behavior on empty filename**: `entry.path().filename().string().front()` is UB if the filename string is empty. Use `starts_with('.')` (C++20) or check `!s.empty() && s[0] == '.'`.
- [x] **Sort key mismatch**: Files are sorted by full `fs::path` but printed by `filename()` only. Sort on the displayed key so ordering matches output if path handling ever changes.
- [ ] **Empty positional argument falls through**: An empty arg (`""`) bypasses the `argv[i][0] == '-'` check and is assigned as the path, only failing later at validation. Reject with a clearer message up front (e.g. check `*argv[i] == '\0'`).
- [ ] **No `--` separator**: There's no way to pass a path that starts with `-` (e.g. a directory literally named `-foo`). Add the conventional `--` end-of-options marker.
- [ ] **Throwing `is_regular_file()`**: A broken symlink encountered mid-iteration throws `filesystem_error`, aborting the entire listing. Use the non-throwing `entry.is_regular_file(ec)` overload to skip the bad entry and continue.

## Robustness & Error Handling
- [x] **Directory access handling**: Wrap directory iteration in `try-catch` blocks to handle `std::filesystem::filesystem_error` (e.g., permission denied, non-existent path).
- [x] **Validation**: Ensure the provided path exists and is indeed a directory before processing.

## Build System (CMake)
- [ ] **Refactor redundant flags**: Consolidate global `CMAKE_CXX_FLAGS_<TYPE>` settings and the `add_custom_flags` function to follow DRY (Don't Repeat Yourself) principles.
- [ ] **Multi-config generator support**: Update the build logic to better support generators like Visual Studio and Xcode where `CMAKE_BUILD_TYPE` is not available at generation time.
- [ ] **Use target-scoped warning flags**: Replace global `CMAKE_CXX_FLAGS = "-Wall -Wextra -pedantic"` with `target_compile_options(dcl PRIVATE ...)`.
- [ ] **Bump `cmake_minimum_required`**: 3.10 is older than necessary; 3.16+ unlocks cleaner generator-expression patterns.
- [ ] **MSan caveat**: MemorySanitizer requires an instrumented libc++ to avoid false positives. Either document this limitation or remove the MSAN build type.

## Build Scripts
- [ ] **`run-builds.bat` builds the wrong solution**: Line 30 invokes `msbuild dirsize.sln`, but this project's solution is `declutter.sln`. Switch to `cmake --build .` to match `run-builds.ps1`.
- [ ] **`run-builds.bash` lacks strict mode**: Add `set -euo pipefail` and quote `"$BUILD_DIR"` so a failed `cd` doesn't cause subsequent commands to run in the wrong directory.
- [ ] **`run-builds.ps1` dead code**: The pre-loop `New-Item` creating `$buildDir` is immediately wiped on the first iteration — remove it.

## Quality Assurance
- [ ] **Automated Testing**: Implement a test suite to verify file grouping logic and error handling.
- [ ] **CI/CD**: Expand the GitHub Actions workflow to run tests across different platforms.
- [ ] **Update outdated CI actions**: `actions/checkout@v3` should be bumped to `@v4`.
- [ ] **Drop or populate `ctest` step**: With no tests defined, `ctest -C Release` is a silent no-op; either add tests or remove the step until there are some.
- [ ] **Add a sanitizer CI job**: ASAN/UBSAN build types are defined locally but never exercised in CI. Add a job that builds and runs with `-DCMAKE_BUILD_TYPE=ASAN` (and/or UBSAN).

