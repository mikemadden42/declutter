# declutter

A small C++17 command-line utility that lists the files in a directory grouped by their extension. Useful for getting a quick overview of what kinds of files live in a cluttered folder.

## Features

- Groups regular files by extension and prints them under per-extension headings.
- Sorts files alphabetically within each group.
- Skips hidden files (those whose name starts with `.`) by default; pass `-a` / `--all` to include them.
- Files without an extension are listed under `No Extension`.
- Accepts an optional directory path; defaults to the current directory.

## Requirements

- A C++17 compiler (GCC, Clang, or MSVC).
- CMake 3.10 or newer.

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
| `UBSAN`         | UndefinedBehaviorSanitizer                           |
| `TSAN`          | ThreadSanitizer (not supported on MSVC)              |
| `MSAN`          | MemorySanitizer (Clang only; needs instrumented libc++) |
| `COVERAGE`      | Code coverage instrumentation                        |

Helper scripts run every build type sequentially:

- Linux/macOS: `./run-builds.bash`
- Windows (cmd): `run-builds.bat`
- Windows (PowerShell): `./run-builds.ps1`

## Usage

```
dcl [-a|--all] [-h|--help] [path]

  -a, --all   Include hidden files (those starting with '.')
  -h, --help  Show this help message
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
