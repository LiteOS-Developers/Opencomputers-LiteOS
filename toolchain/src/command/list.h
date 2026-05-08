#ifndef COMMAND_LIST_H
#define COMMAND_LIST_H

#include "../command.h"
#include "../common.h"
#include <map>
#include <string>
#include <vector>

class ListCommand: public ICommand
{
  public: 
    ListCommand(); 
    successfull_t execute(std::map<std::string, argumentValue_t> args) override;
};

#endif
