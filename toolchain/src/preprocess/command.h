#ifndef PREPROCESS_COMMAND_H
#define PREPROCESS_COMMAND_H

#include "../command.h"
#include "../common.h"
#include <filesystem>
#include <map>
#include <string>
#include <vector>

class PreprocessCommand: public ICommand
{
  public: 
    PreprocessCommand(); 
    successfull_t execute(std::map<std::string, argumentValue_t> args) override;
};

#endif
