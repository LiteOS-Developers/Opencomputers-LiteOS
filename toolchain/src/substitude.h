#ifndef SUBSTITUDE_H
#define SUBSTITUDE_H
#include <string>
#include <regex>
#include <unordered_map>

std::string substitute(std::string input, std::unordered_map<std::string, std::string>& locals, std::unordered_map<std::string, std::string>& globals);

#endif
