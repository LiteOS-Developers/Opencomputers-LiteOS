#ifndef PREPROCESS_H
#define PREPROCESS_H

#include <string>
#include <vector>
#include <unordered_map>
#include <fstream>
#include <filesystem>
#include "../common.h"

successfull_t preprocess(std::string inFile, std::unordered_map<std::string, std::string> defines, std::filesystem::path baseDir);

#endif
