#include "command.h"

#if 0
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
      if(start < length && opts.at(start) == ' ')
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
    arg = trim(arg);
    if(arg.length() == 0) continue;
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
#endif

std::map<std::string, ICommand*> commands;

void registerCommands() {
  commands = std::map<std::string, ICommand*>();
  commands["preprocess"] = new PreprocessCommand();
  commands["echo"] = new EchoCommand();
  commands["write"] = new WriteCommand();
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

#if 0
successfull_t execute2(std::string command, std::string opts, table& globals, table& locals) {
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
  } else if(command == "echo") {
    std::string result = "";
    unsigned long int size = args.size();
    for(unsigned long int i = 0; i < size; i++) {
      result += args.at(i) + " ";
    }
    return {.status = STATE_SUCCESS, .output = result};
  } else if(command == "list") {
    if(args.size() < 1) {
      printf("list: Invalid Usage. Usage: list <path> <recursive:true/false> <type:file/dir>\n");
      return {.status = STATE_ERROR, .output = ""};
    }
    std::filesystem::path path = std::filesystem::path(args.at(0));
    if(!std::filesystem::exists(path)) {
      printf("list: Path does not exists\n");
      return {.status = STATE_ERROR, .output = ""};
    }

    std::string type = "file";
    bool recursive = false;

    if(args.size() >= 2) {
      recursive = args.at(1) == "true";
    }
    if(args.size() >= 3) {
      type = args.at(2);
    }
    std::string result = "";
    if(recursive) { 
      for(auto const& entry : std::filesystem::recursive_directory_iterator(path)) {
        if((entry.is_directory() && type == "dir") || (entry.is_regular_file() && type == "file")) {
          result += entry.path().string() + " ";
        }
      } 
    } else {
       for(auto const& entry : std::filesystem::directory_iterator(path)) {
        if((entry.is_directory() && type == "dir") || (entry.is_regular_file() && type == "file")) {
          result += entry.path().string() + " ";
        }
      }
    }

    return {.status = STATE_SUCCESS, .output = result};
  } else if (command == "child") {
    if (args.size() < 1) {
      printf("child: missing Argument <path>\n");
      return {.status = STATE_ERROR, .output = ""};
    }
    std::filesystem::path path = std::filesystem::path(args.at(0));
    if(std::filesystem::exists(path) && std::filesystem::is_regular_file(path)) {
      if(runFile(path.string())) {
        return {.status = STATE_SUCCESS, .output = ""};
      }
      printf("child: Error in Children. See above for more error\n");
      return {.status = STATE_ERROR, .output = ""};
    } else {
      printf("child: Argument is not a valid file\n");
      return {.status = STATE_ERROR, .output = ""};
    }
  }
  printf("Unknown Command %s\n", command.c_str());
  return {
    .status = STATE_ERROR,
    .output = "",
  };
}
#endif
