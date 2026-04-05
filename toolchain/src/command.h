#ifndef COMMAND_H
#define COMMAND_H

#include <string>
#include <vector>
#include <stdio.h>
#include "./common.h"
#include "preprocess/preprocess.h"
#include "runCommand.h"

enum argtype_type_t {
  ARGTYPE_SUBCOMMAND,
  ARGTYPE_VALUE,
};

struct argtype {
  argtype_type_t type;
  std::string value;
};



successfull_t execute(std::string command, std::string opts, table& globals, table& locals);
 

#endif
