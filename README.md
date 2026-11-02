# declutter

A small C++17 command-line utility that lists the files in a directory grouped by their extension. Useful for getting a quick overview of what kinds of files live in a cluttered folder.

## Features

- Groups regular files by extension and prints them under per-extension headings.
- Sorts files alphabetically within each group.
- Skips hidden files (those whose name starts with `.`) by default; pass `-a` / `--all` to include them.
- Files without an extension (including names ending in a bare `.`, like `foo.`) are listed under `No Extension`.
- Accepts an optional directory path; defaults to the current directory.

## Requirements

- A C++17 compiler (GCC, Clang, or MSVC).
- CMake 3.16 or newer.

## Building

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

The resulting executable is `build/dcl`.

### Build types

In addition to the standard `Debug`, `Release`, and `RelWithDebInfo`, the project defines sanitizer and coverage build types:

| Build type      | Purpose                                              |
| --------------- | ---------------------------------------------------- |
| `Debug`         | Unoptimized build with debug symbols                 |
| `Release`       | Optimized build                                      |
| `RelWithDebInfo`| Optimized build with debug symbols                   |
| `ASAN`          | AddressSanitizer                                     |
| `UBSAN`         | UndefinedBehaviorSanitizer (not on MSVC)             |
| `TSAN`          | ThreadSanitizer (not on MSVC)                        |
| `MSAN`          | MemorySanitizer (Clang on Linux only; needs instrumented libc++) |
| `COVERAGE`      | Code coverage instrumentation (not on MSVC)          |

Selecting a build type the current compiler/platform can't support fails at configure time with a clear error. With multi-config generators (Visual Studio, Xcode, Ninja Multi-Config), only the supported types are offered, and you pick one at build time with `cmake --build build --config ASAN`.

On macOS a universal (`x86_64;arm64`) binary is built by default; pass `-DCMAKE_OSX_ARCHITECTURES=arm64` (or similar) to override.

Helper scripts run every build type sequentially. Types the current platform can't build (e.g. `MSAN` on macOS) are reported as skipped and don't affect the exit status:

- Linux/macOS: `./run-builds.bash`
- Windows (cmd): `run-builds.bat`
- Windows (PowerShell): `./run-builds.ps1`

## Testing

Tests are CMake scripts driven by CTest; each case builds a fixture directory and checks `dcl`'s output and exit code:

```bash
cmake -B build
cmake --build build
cd build && ctest --output-on-failure
```

## Usage

```
dcl [-a|--all] [-h|--help] [--] [path]

  -a, --all   Include hidden files (those starting with '.')
  -h, --help  Show this help message
  --          Treat all following arguments as paths
  path        Directory to inspect (default: current directory)
```

Examples:

```bash
# List files in the current directory
dcl

# List files in a specific directory
dcl ~/Downloads

# Include hidden files
dcl -a ~/Downloads

# Inspect a directory whose name starts with '-'
dcl -- -weird-name
```

### Example output

```
No Extension:
- Makefile

cc:
- main.cc

md:
- README.md
- TODO.md

txt:
- CMakeLists.txt
```

## License

See [LICENSE](LICENSE).
