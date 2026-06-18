#ifndef COMMAND_CHILD_H
#define COMMAND_CHILD_H

#include "../command.h"
#include "../common.h"
#include <map>
#include <string>
#include <vector>

class ChildCommand: public ICommand
{
  public: 
    ChildCommand(); 
    successfull_t execute(std::map<std::string, argumentValue_t> args) override;
};

#endif
