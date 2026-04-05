#include "command.h"

std::vector<argtype> make_arguments(std::string opts) {
  std::vector<argtype> args = std::vector<argtype>();
  size_t start = 0;
  size_t length = opts.length();

  while (start < length) {
    std::string arg = "";

    if(opts.at(start) == '"') {
      size_t pos = opts.find('"', start+1);
      if(pos == std::string::npos) pos = length;      
    
      arg = opts.substr(start + 1, pos-start);
      
      if(arg.back() == '"') {
        arg.pop_back();
      }
      start = pos + 1;
    } else if(opts.substr(start, 2) == "$(") {
      size_t pos = opts.find(')', start);
      if(pos == std::string::npos || start + 2 > pos) {
        printf("Unterminated Subcommand: %s", opts.c_str());
        std::exit(-1);
        return {};
      }
      std::string subcmd = opts.substr(start+2, pos - (start + 2));
      start = pos + 1;
      if(opts.at(start) == ' ')
        start++;

      args.push_back({
        .type = ARGTYPE_SUBCOMMAND,
        .value = subcmd,
      });
      continue;
    } else {
      size_t pos = opts.find(' ', start);
      if(pos == std::string::npos) pos = length;
      arg = opts.substr(start, pos-start);
      start += arg.length() + 1;
    }
    args.push_back({
      .type = ARGTYPE_VALUE,
      .value = arg
    });
  }
  return args;
}

std::vector<std::string> post_process_arguments(std::vector<argtype> arguments, table& globals, table& locals) {
  std::vector<std::string> args = std::vector<std::string>();

  for(unsigned long int i = 0; i < arguments.size(); i++) {
    argtype arg = arguments.at(i);
    if(arg.type == ARGTYPE_VALUE) {
      args.push_back(arg.value);
    } else if(arg.type == ARGTYPE_SUBCOMMAND) {
      successfull_t cmdResult = runCommand(arg.value, globals, locals);
      if(cmdResult.status == STATE_ERROR) {
        printf("post_process_arguments: Failed running Subcommand\n");
        std::exit(-1);
        while(true){} // never return
      }
      args.push_back(cmdResult.output);
    }
  }
  return args;
}

successfull_t execute(std::string command, std::string opts, table& globals, table& locals) {
  std::vector<argtype> argtypes = make_arguments(opts);
  std::vector<std::string> args = post_process_arguments(argtypes, globals, locals);

  if(command == "preprocess") {
    std::string inFile = "";
    std::unordered_map<std::string, std::string> defines;
    
    if (args.size() == 0) {
      printf("preprocess: no arguments passed\n");
      return {
        .status = STATE_ERROR,
        .output = "",
      };
    }

    for(unsigned long int i = 0; i < args.size(); i++) {
      std::string value = args.at(i);
      if(value.substr(0, 2).compare("-D") == 0) {
        defines[value.substr(2, value.length())] = "";
      } else {
        inFile = args.at(i);
      }
    }

    return preprocess(inFile, defines, std::filesystem::current_path());
  } else if(command == "write") {
    std::string text = args.at(0);
    std::string outFile = args.at(1);

    
    std::ofstream out(outFile);
    if(!out) {
      printf("write: Failed to write %ld bytes into %s: Destination does not exists\n", text.length(), outFile.c_str());
      return {.status = STATE_ERROR, .output = ""};
    }
    out << text;
    return {.status = STATE_SUCCESS, .output = "",};
  }
  printf("Unknown Command %s\n", command.c_str());
  return {
    .status = STATE_ERROR,
    .output = "",
  };
}
