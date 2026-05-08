#ifndef COMMAND_WRITE_H
#define COMMAND_WRITE_H

#include "../command.h"
#include "../common.h"
#include <map>
#include <string>
#include <vector>

class WriteCommand: public ICommand
{
  public: 
    WriteCommand(); 
    successfull_t execute(std::map<std::string, argumentValue_t> args) override;
};

#endif
