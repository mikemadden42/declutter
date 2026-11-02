# Project TODOs

## Features
- [x] **Command-line argument support**: Allow users to specify the directory path as an argument instead of defaulting to the current directory (`.`).
- [x] **Hidden files option**: Add a flag to optionally include hidden files (those starting with a `.`) in the output.

## Code Correctness (`main.cc`)
- [x] **Undefined behavior on empty filename**: `entry.path().filename().string().front()` is UB if the filename string is empty. Use `starts_with('.')` (C++20) or check `!s.empty() && s[0] == '.'`.
- [x] **Sort key mismatch**: Files are sorted by full `fs::path` but printed by `filename()` only. Sort on the displayed key so ordering matches output if path handling ever changes.
- [x] **Empty positional argument falls through**: An empty arg (`""`) bypasses the `argv[i][0] == '-'` check and is assigned as the path, only failing later at validation. Reject with a clearer message up front (e.g. check `*argv[i] == '\0'`).
- [x] **No `--` separator**: There's no way to pass a path that starts with `-` (e.g. a directory literally named `-foo`). Add the conventional `--` end-of-options marker.
- [x] **Throwing `is_regular_file()`**: A status error encountered mid-iteration (e.g. permission denied resolving a symlink) throws `filesystem_error`, aborting the entire listing. A plain dangling symlink does *not* throw (not-found is reported as a status, verified on macOS/libc++). Use the non-throwing `entry.is_regular_file(ec)` overload to skip the bad entry and continue.
- [x] **Trailing-dot filename prints an empty heading**: For `foo.`, `extension()` returns `"."`, so `substr(1)` yields `""` and the group prints as a bare `:`. Treat `"."` like no extension, or display it literally.
- [x] **Misleading "does not exist" error**: If `fs::exists(path, ec)` fails with an error (e.g. permission denied), the message still says the path does not exist. Report `ec.message()` when `ec` is set.
- [ ] **Case-sensitive grouping and sorting**: `a.JPG` and `b.jpg` land in separate groups, and `Zeta.txt` sorts before `alpha.txt`. Consider case-insensitive grouping/sorting (or a flag for it).

## Robustness & Error Handling
- [x] **Directory access handling**: Wrap directory iteration in `try-catch` blocks to handle `std::filesystem::filesystem_error` (e.g., permission denied, non-existent path).
- [x] **Validation**: Ensure the provided path exists and is indeed a directory before processing.

## Build System (CMake)
- [ ] **Refactor redundant flags**: Consolidate global `CMAKE_CXX_FLAGS_<TYPE>` settings and the `add_custom_flags` function to follow DRY (Don't Repeat Yourself) principles.
- [ ] **Multi-config generator support**: Update the build logic to better support generators like Visual Studio and Xcode where `CMAKE_BUILD_TYPE` is not available at generation time.
- [ ] **Use target-scoped warning flags**: Replace global `CMAKE_CXX_FLAGS = "-Wall -Wextra -pedantic"` with `target_compile_options(dcl PRIVATE ...)`. The current `set()` also clobbers any user-supplied `CXXFLAGS`.
- [ ] **Bump `cmake_minimum_required`**: 3.10 is older than necessary; 3.16+ unlocks cleaner generator-expression patterns.
- [ ] **MSan caveat**: MemorySanitizer requires an instrumented libc++ to avoid false positives. Either document this limitation or remove the MSAN build type.
- [ ] **Broken MSVC flags**: MSVC does not support `/fsanitize=undefined`, so UBSAN cannot work there. `/COVERAGE` is not a `cl.exe` flag and `/DEBUG` is a linker flag. `target_compile_options(... "/O2 /DEBUG")` and `"/DEBUG /COVERAGE"` pass a single space-containing argument instead of two flags.
- [ ] **Forced universal macOS build**: `OSX_ARCHITECTURES "x86_64;arm64"` overrides a user's `CMAKE_OSX_ARCHITECTURES`. MSAN is unsupported on macOS entirely, and TSAN with universal builds is fragile. Only default it when the user hasn't set one.
- [ ] **Inaccurate Release comment**: The comment says "assume -O2 is already present", but CMake's default Release flags are `-O3 -DNDEBUG`.

## Build Scripts
- [ ] **`run-builds.bat` builds the wrong solution**: Line 30 invokes `msbuild dirsize.sln`, but this project's solution is `declutter.sln`. Switch to `cmake --build .` to match `run-builds.ps1`.
- [ ] **`run-builds.bat` never detects failures**: `%errorlevel%` inside the parenthesized `for` block (lines 29, 31) is expanded once at parse time, so every build reports success. Use `!errorlevel!` (delayed expansion is already enabled) or `if errorlevel 1`.
- [ ] **`run-builds.bash` lacks strict mode**: Add `set -euo pipefail` and quote `"$BUILD_DIR"` so a failed `cd` doesn't cause subsequent commands to run in the wrong directory. Caveat: `((success_count++))` returns status 1 when the counter is 0, so `set -e` would kill the script after the first success; switch to `success_count=$((success_count + 1))`. Also check the `cmake` configure exit code and use `cmake --build .` instead of `make`.
- [ ] **`run-builds.ps1` hides compiler errors**: `$buildResult = cmake --build ...` captures and discards the build output, so failures print only "build failed." Let the output stream through. The configure step's exit code is also never checked.
- [ ] **`run-builds.ps1` dead code**: The pre-loop `New-Item` creating `$buildDir` is immediately wiped on the first iteration — remove it.

## Quality Assurance
- [x] **Automated Testing**: Implement a test suite to verify file grouping logic and error handling.
- [ ] **CI/CD**: Expand the GitHub Actions workflow to run tests across different platforms.
- [ ] **Update outdated CI actions**: `actions/checkout@v3` should be bumped to `@v4`.
- [x] **Drop or populate `ctest` step**: With no tests defined, `ctest -C Release` is a silent no-op; either add tests or remove the step until there are some.
- [ ] **Add a sanitizer CI job**: ASAN/UBSAN build types are defined locally but never exercised in CI. Add a job that builds and runs with `-DCMAKE_BUILD_TYPE=ASAN` (and/or UBSAN).

