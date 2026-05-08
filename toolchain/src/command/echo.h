#ifndef COMMAND_ECHO_H
#define COMMAND_ECHO_H

#include "../command.h"
#include "../common.h"
#include <map>
#include <string>
#include <vector>

class EchoCommand: public ICommand
{
  public: 
    EchoCommand(); 
    successfull_t execute(std::map<std::string, argumentValue_t> args) override;
};

#endif
