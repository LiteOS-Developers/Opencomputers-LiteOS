#include "common.h"

std::string trim(const std::string &s) {
    size_t start = s.find_first_not_of(" \t\n\r");
    size_t end = s.find_last_not_of(" \t\n\r");
    return (start == std::string::npos) ? "" : s.substr(start, end - start + 1);
}


std::string untilSpace(std::string line) {
  std::string command;
  return line.substr(0, line.find(' '));
}


