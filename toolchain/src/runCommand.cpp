#include "runCommand.h"
#include <cstring>

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

std::string processArgument(std::string line) {
  if(line.length() == 0) return "";
  std::string arg = "";

  bool inString = line.at(0) == '"';
  for(size_t i = 0; i < line.length(); i++) {
    // printf("%d at %llu '%c' %d\n", inString, i, line.at(i), line.at(i) == ' ');
    if(line.at(i) == ' ' && !inString) {
      return arg;
    } else if(line.at(i) == '"' && inString && i != 0) {
      arg.push_back(line.at(i));
      return arg;
    }
    arg.push_back(line.at(i));
  }
  return arg;
}

bool executeStmt(std::string line, std::ifstream* in, std::unordered_map<std::string, std::string> locals, std::unordered_map<std::string, std::string> globals) {
  if(line.substr(0, 3) == "if ") {
    line = line.substr(3, line.length() - 3);
    size_t space = line.find(' ');
    
    if(space == std::string::npos) {
      printf("if: missing space after operator\n");
      return false;
    }

    std::string op = line.substr(0, space);
    std::string args = trim(line.substr(op.length() + 1, line.length() - op.length() - 1));

    bool runBlock = false;
    if(op == "eq") {
      std::string left = processArgument(args);
      args = trim(args.substr(left.length(), args.length() - left.length()));
      std::string right = processArgument(args);

      left = left.front() == '"' && left.back() == '"' ? left.substr(1, left.length() - 2) : left;
      right = right.front() == '"' && right.back() == '"' ? right.substr(1, right.length() - 2) : right;

      runBlock = strcmp(left.c_str(), right.c_str()) == 0;
    } else if(op == "neq") {
      std::string left = processArgument(args);
      args = trim(args.substr(left.length(), args.length() - left.length()));
      std::string right = processArgument(args);

      left = left.front() == '"' && left.back() == '"' ? left.substr(1, left.length() - 2) : left;
      right = right.front() == '"' && right.back() == '"' ? right.substr(1, right.length() - 2) : right;

      runBlock = strcmp(left.c_str(), right.c_str()) != 0; 
    } else {
      printf("if: Invalid Operator %s\n", op.c_str());
      return false; 
    }
     
    std::string block_line;
    bool endIfReached = false;
    
    while(std::getline(*in, block_line)) {
      block_line = trim(block_line);
      if(block_line.find("endif") != std::string::npos) { endIfReached = true; break; }
      if(block_line.find("else") != std::string::npos) break;
      printf("%s\n", block_line.c_str());
      if(runBlock) {
        if(!executeStmt(block_line, &(*in), locals, globals)) {
          return false;
        }
      }
    }

    while(std::getline(*in, block_line) && !endIfReached) {
      block_line = trim(block_line);
      if(block_line.find("endif") != std::string::npos) break;
      if(!runBlock) {
        if(!executeStmt(block_line, &(*in), locals, globals)) {
          return false;
        }
      }
    }
    printf("runBlock: %d\n", runBlock);
    return true;
  } else {
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
      if(status.status == STATE_ERROR) return false;
      else {
        if(status.output.length() > 0) {
          printf("%s\n", status.output.c_str());
        }
      }
    }
    return true;
  }
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
      executeStmt(line, &in, locals, globals);
    }
  }
  return true;
}
