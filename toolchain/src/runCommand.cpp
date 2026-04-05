#include "runCommand.h"

successfull_t runCommand(std::string line, table& globals, table& locals) {
  line = substitute(line, locals, globals);

  std::string command = untilSpace(line);
  std::string opts = line.substr(command.length() + 1);

  successfull_t result = execute(command, opts, globals, locals);
  
  if(result.status == STATE_ERROR) {
    printf("Error. See above for details\n");
    return {.status = STATE_ERROR, .output = ""};
  }
  return result;
}


