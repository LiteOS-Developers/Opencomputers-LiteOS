#include "command.h"

std::map<std::string, ICommand*> commands;

void registerCommands() {
  commands = std::map<std::string, ICommand*>();
  commands["preprocess"] = new PreprocessCommand();
  commands["echo"] = new EchoCommand();
  commands["write"] = new WriteCommand();
  commands["list"] = new ListCommand();
  commands["child"] = new ChildCommand();
}

successfull_t execute(std::string commandName, std::string args, table& globals, table& locals) {
  if(!commands.contains(commandName)) {
    printf("execute: %s not a command\n", commandName.c_str());
    return {.status = STATE_ERROR, .output = ""};
  }
  ICommand* command = commands[commandName];
  auto parsedArgs = std::map<std::string, argumentValue_t>();
  auto spaceSep = std::vector<std::string>();
  auto processedArgs = std::map<std::string, argumentValue_t>();

  if(command->m_arguments.contains("")) {
    if(command->m_arguments[""] == ARGUMENT_VALUE_ALL) {
      processedArgs[""] = {
        .type = ARGUMENT_VALUE_ALL,
        .data = args,
      };
      return command->execute(processedArgs);
    }
  }

  
  std::string current = "";

  for(unsigned long int i = 0; i < args.size(); i++) {
    if((args.at(i) == ' ' && !(current.substr(0, 2) == "$(")) || args.at(i) == ')') {
      if(current.substr(0, 2) == "$(" && args.at(i) == ')') {
        std::string subCmd = current.substr(2, current.size() - 2);
        successfull_t result = runCommand(subCmd, globals, locals);
        if(result.status == STATE_ERROR) {
          printf("subcommand: Failed with error. See above for error\n");
          return {.status = STATE_ERROR, .output = ""};
        }
        current = result.output;
      }

      if(current.size() > 0) spaceSep.push_back(current);
      current = "";
    } else {
      current.push_back(args.at(i));
    }
  }
  if(current.size() > 0) spaceSep.push_back(current);

  for(unsigned long int i = 0; i < spaceSep.size(); i++ ) {
    std::string key = spaceSep.at(i);
 
    if(command->m_arguments.contains(key)) { 
      auto argument = command->m_arguments[key];
      argumentValue_t a = {.type = argument, .data = ""};
      if(argument == ARGUMENT_VALUE_SUBCOMMAND) {
        a.data = key;
      } else if(argument == ARGUMENT_VALUE_FLAG_VALUE) {
        if(i + 1 >= spaceSep.size()) {
          printf("%s: not enough arguments\n", commandName.c_str());
          return {.status = STATE_ERROR, .output = ""};
        }
        a.data = spaceSep.at(++i);
      } else if(argument == ARGUMENT_VALUE_FLAG_TOGGLE) {
        a.data = 1;
      } else {
        printf("%s: %s is invalid argument.\n", commandName.c_str(), key.c_str());
        return {.status = STATE_ERROR, .output = ""};
      }
      processedArgs[key] = a;
    } else if(command->m_arguments.contains("")) {
      if(processedArgs.contains("")) {
        printf("%s: only one positional argument allowed.\n", commandName.c_str());
        return {.status = STATE_ERROR, .output = ""};
      }
      processedArgs[""] = {
        .type = ARGUMENT_VALUE_VALUE,
        .data = key
      };
    } else {
      printf("%s: %s is not a valid option", commandName.c_str(), key.c_str());
      return {.status = STATE_ERROR, .output = ""};
    } 
  }
  
  return command->execute(processedArgs);
}

