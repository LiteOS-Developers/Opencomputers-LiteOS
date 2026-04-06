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

bool runFile(std::string file) {
  std::ifstream in(file);
  if (!in.good()) {
    printf("Cannot find file %s\n", file.c_str());
    return -1;
  }

  std::string line;

  bool inStep = false;
  std::unordered_map<std::string, std::string> globals;
  std::unordered_map<std::string, std::string> locals;
 
  while (std::getline(in, line)) {
    line = trim(line);
    if (line.empty()) continue;

    // Finish
    if (line == "finish") break;

    // Global variable
    if (line.find('=') != std::string::npos) {
      auto pos = line.find('=');
      std::string key = trim(line.substr(0, pos));
      std::string value = trim(line.substr(pos + 1));

      // Remove quotes
      if (value.front() == '"' && value.back() == '"') {
        value = value.substr(1, value.size() - 2);
      }
      else if(value.substr(0, 2) == "$(") {
        std::string subcmd = value.substr(2, value.find(')') - 2);
        successfull_t result;
        if(!inStep) {
          locals.clear();
        }
        result = runCommand(subcmd, globals, locals);
        
        if(result.status == STATE_ERROR) {
          printf("toolchain: Error in Subcommand. See above for more details.\n");
          return false;
        }
        value = result.output; 
      }

      if (!inStep) {
        globals[key] = value;
      } else {
        locals[key] = value;
      }
      continue;
    }

    // Step start
    if (line.rfind("step", 0) == 0) {
      inStep = true;
      locals.clear();
      continue;
    }

    // Step end
    if (line == "}") {
      inStep = false;
      continue;
    }

    // Inside step
    if (inStep) {
      // Local variable definition
      if (line.find('=') != std::string::npos) {
        auto pos = line.find('=');     

        std::string key = trim(line.substr(0, pos));
        std::string value = trim(line.substr(pos + 1));

        if (value.front() == '"' && value.back() == '"') {
          value = value.substr(1, value.size() - 2);
        }

        locals[key] = value;
      } else {
        successfull_t status = runCommand(line, locals, globals);
        if(status.status == STATE_ERROR) break;
        else {
          if(status.output.length() > 0) {
            printf("%s\n", status.output.c_str());
          }
        }
      }
    }
  }
  return true;
}
