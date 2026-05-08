#ifndef COMMAND_H
#define COMMAND_H

#include <string>
#include <vector>
#include <stdio.h>
#include "./common.h"
#include "preprocess/preprocess.h"
#include "runCommand.h"
#include <map>

class ICommand {
  public:
    virtual successfull_t execute(std::map<std::string, argumentValue_t> args) = 0;
    std::map<std::string, ArgumentValueType> m_arguments;
    std::string m_name;
};

void registerCommands();
successfull_t execute(std::string command, std::string opts, table& globals, table& locals);

#include "preprocess/command.h"
#include "command/echo.h"
#include "command/write.h"
#include "command/list.h"

#endif
