#ifndef COMMON_H
#define COMMON_H

#include <string>
#include <cstdint>
#include <unordered_map>
#include <string>

using table = std::unordered_map<std::string, std::string>;

std::string trim(const std::string &s);
std::string untilSpace(std::string line);

enum state_t {
  STATE_SUCCESS = 0,
  STATE_ERROR,
};

struct successfull_t {
  state_t status;
  std::string output;
};

#endif
