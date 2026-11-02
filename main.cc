#include <algorithm>
#include <cctype>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <map>
#include <string>
#include <system_error>
#include <vector>

namespace fs = std::filesystem;

namespace {

void print_usage(const char* prog) {
    std::cout << "Usage: " << prog << " [-a|--all] [-h|--help] [--] [path]\n"
              << "  -a, --all   Include hidden files (those starting with '.')\n"
              << "  -h, --help  Show this help message\n"
              << "  --          Treat all following arguments as paths\n"
              << "  path        Directory to inspect (default: current directory)\n";
}

std::string to_lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return s;
}

// Alphabetical ignoring case; names differing only in case keep a fixed order.
bool less_ignoring_case(const std::string& a, const std::string& b) {
    std::string lower_a = to_lower(a);
    std::string lower_b = to_lower(b);
    if (lower_a != lower_b) return lower_a < lower_b;
    return a < b;
}

}  // namespace

int main(int argc, char* argv[]) {
    std::string path = ".";
    bool show_hidden = false;
    bool path_set = false;
    bool end_of_options = false;

    for (int i = 1; i < argc; ++i) {
        const char* arg = argv[i];
        if (!end_of_options && arg[0] == '-') {
            if (std::strcmp(arg, "--") == 0) {
                end_of_options = true;
            } else if (std::strcmp(arg, "-a") == 0 ||
                       std::strcmp(arg, "--all") == 0) {
                show_hidden = true;
            } else if (std::strcmp(arg, "-h") == 0 ||
                       std::strcmp(arg, "--help") == 0) {
                print_usage(argv[0]);
                return 0;
            } else {
                std::cerr << "Unknown option: " << arg << "\n";
                print_usage(argv[0]);
                return 2;
            }
        } else if (arg[0] == '\0') {
            std::cerr << "Error: path argument is empty\n";
            return 2;
        } else if (!path_set) {
            path = arg;
            path_set = true;
        } else {
            std::cerr << "Unexpected argument: " << arg << "\n";
            return 2;
        }
    }

    std::error_code ec;
    bool exists = fs::exists(path, ec);
    if (ec) {
        std::cerr << "Error: cannot access " << path << ": " << ec.message()
                  << "\n";
        return 1;
    }
    if (!exists) {
        std::cerr << "Error: path does not exist: " << path << "\n";
        return 1;
    }
    bool is_directory = fs::is_directory(path, ec);
    if (ec) {
        std::cerr << "Error: cannot access " << path << ": " << ec.message()
                  << "\n";
        return 1;
    }
    if (!is_directory) {
        std::cerr << "Error: not a directory: " << path << "\n";
        return 1;
    }

    std::map<std::string, std::vector<std::string>> files_by_extension;

    try {
        for (const auto& entry : fs::directory_iterator(path)) {
            // Skip entries whose status can't be read rather than aborting.
            std::error_code entry_ec;
            if (!entry.is_regular_file(entry_ec)) continue;
            std::string name = entry.path().filename().string();
            if (!show_hidden && !name.empty() && name[0] == '.') continue;
            // Group case-insensitively, so ".JPG" and ".jpg" share a heading.
            std::string extension =
                to_lower(entry.path().extension().string());
            // "foo." has extension "."; group it with extensionless files.
            if (extension == ".") extension.clear();
            files_by_extension[extension].push_back(std::move(name));
        }
    } catch (const fs::filesystem_error& e) {
        std::cerr << "Error reading directory: " << e.what() << "\n";
        return 1;
    }

    for (auto& [extension, names] : files_by_extension) {
        std::sort(names.begin(), names.end(), less_ignoring_case);
        std::string display_extension =
            extension.empty() ? "No Extension" : extension.substr(1);
        std::cout << display_extension << ":\n";
        for (const auto& name : names) {
            std::cout << "- " << name << "\n";
        }
        std::cout << "\n";
    }

    return 0;
}
