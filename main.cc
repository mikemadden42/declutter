#include <algorithm>
#include <filesystem>
#include <iostream>
#include <map>
#include <vector>

namespace fs = std::filesystem;

int main() {
    std::string path = ".";  // Current directory
    std::map<std::string, std::vector<fs::path>> files_by_extension;

    // Collect files and group by extension
    for (const auto& entry : fs::directory_iterator(path)) {
        if (entry.is_regular_file() &&
            entry.path().filename().string().front() != '.') {
            std::string extension = entry.path().extension().string();
            files_by_extension[extension].push_back(entry.path());
        }
    }

    // Sort files within each extension group and print them
    for (auto& [extension, paths] : files_by_extension) {
        std::sort(paths.begin(), paths.end());
        std::string display_extension =
            extension.empty() ? "No Extension"
                              : extension.substr(1);  // Remove the first dot
        std::cout << display_extension << ":" << std::endl;
        for (const auto& file : paths) {
            std::cout << "- " << file.filename().string() << std::endl;
        }
        std::cout << std::endl;
    }

    return 0;
}
