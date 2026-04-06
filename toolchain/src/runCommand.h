#ifndef RUNCOMMAND_H
#define RUNCOMMAND_H
#include <stdbool.h>
#include <string>
#include <unordered_map>
#include <fstream>  

#include "common.h"
#include "substitude.h"
#include "command.h"

successfull_t runCommand(std::string line, table& globals, table& locals);
bool runFile(std::string file);

#endif
