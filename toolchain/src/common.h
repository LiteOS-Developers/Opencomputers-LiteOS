#ifndef COMMON_H
#define COMMON_H

#include <string>
#include <cstdint>
#include <unordered_map>
#include <string>
#include <variant>

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

enum argtype_type_t {
  ARGTYPE_SUBCOMMAND,
  ARGTYPE_VALUE,
};

struct argtype {
  argtype_type_t type;
  std::string value;
};

enum ArgumentValueType {
  ARGUMENT_VALUE_SUBCOMMAND,
  ARGUMENT_VALUE_VALUE,
  ARGUMENT_VALUE_FLAG_TOGGLE,
  ARGUMENT_VALUE_FLAG_VALUE,
  ARGUMENT_VALUE_ALL,
}; 

struct argumentValue_t {
  ArgumentValueType type;
  std::variant<int, std::string> data;
};



#endif
