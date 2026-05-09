#include <algorithm>
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
    std::cout << "Usage: " << prog << " [-a|--all] [-h|--help] [path]\n"
              << "  -a, --all   Include hidden files (those starting with '.')\n"
              << "  -h, --help  Show this help message\n"
              << "  path        Directory to inspect (default: current directory)\n";
}

}  // namespace

int main(int argc, char* argv[]) {
    std::string path = ".";
    bool show_hidden = false;
    bool path_set = false;

    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "-a") == 0 ||
            std::strcmp(argv[i], "--all") == 0) {
            show_hidden = true;
        } else if (std::strcmp(argv[i], "-h") == 0 ||
                   std::strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (argv[i][0] == '-') {
            std::cerr << "Unknown option: " << argv[i] << "\n";
            print_usage(argv[0]);
            return 2;
        } else if (!path_set) {
            path = argv[i];
            path_set = true;
        } else {
            std::cerr << "Unexpected argument: " << argv[i] << "\n";
            return 2;
        }
    }

    std::error_code ec;
    if (!fs::exists(path, ec) || ec) {
        std::cerr << "Error: path does not exist: " << path << "\n";
        return 1;
    }
    if (!fs::is_directory(path, ec) || ec) {
        std::cerr << "Error: not a directory: " << path << "\n";
        return 1;
    }

    std::map<std::string, std::vector<std::string>> files_by_extension;

    try {
        for (const auto& entry : fs::directory_iterator(path)) {
            if (!entry.is_regular_file()) continue;
            std::string name = entry.path().filename().string();
            if (!show_hidden && !name.empty() && name[0] == '.') continue;
            std::string extension = entry.path().extension().string();
            files_by_extension[extension].push_back(std::move(name));
        }
    } catch (const fs::filesystem_error& e) {
        std::cerr << "Error reading directory: " << e.what() << "\n";
        return 1;
    }

    for (auto& [extension, names] : files_by_extension) {
        std::sort(names.begin(), names.end());
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
