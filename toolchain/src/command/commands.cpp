#include "./echo.h"
#include "./write.h"
#include "./list.h"
#include "./child.h"
#include "../runCommand.h"

EchoCommand::EchoCommand() {
  m_name = "echo";
  m_arguments = std::map<std::string, ArgumentValueType>{{"",ARGUMENT_VALUE_ALL}};
}

WriteCommand::WriteCommand() {
  m_name = "write";
  m_arguments = std::map<std::string, ArgumentValueType>{{"", ARGUMENT_VALUE_VALUE}, {"-o", ARGUMENT_VALUE_FLAG_VALUE}};
}

ListCommand::ListCommand() {
  m_name = "list";
  m_arguments = std::map<std::string, ArgumentValueType>{{"", ARGUMENT_VALUE_VALUE}, {"recursive", ARGUMENT_VALUE_FLAG_TOGGLE}, {"-type", ARGUMENT_VALUE_FLAG_VALUE}};
}

ChildCommand::ChildCommand() {
  m_name = "child";
  m_arguments = std::map<std::string, ArgumentValueType>{{"", ARGUMENT_VALUE_VALUE}};
}

successfull_t ChildCommand::execute(std::map<std::string, argumentValue_t> args) {
  if(!args.contains("")) {
    printf("child: missing argument\n");
    return {.status = STATE_ERROR, .output = ""};
  }
  if(runFile(std::get<std::string>(args[""].data))) {
    return {.status = STATE_SUCCESS, .output = ""};
  }
  printf("child: Subfile returned error\n");
  return {.status = STATE_ERROR, .output = ""};
}

successfull_t EchoCommand::execute(std::map<std::string, argumentValue_t> args) {
  if(!args.contains("")) {
    printf("echo: missing argument\n");
    return {.status = STATE_ERROR, .output = ""};
  }
  if(!(args[""].type == ARGUMENT_VALUE_ALL)) {
    printf("echo: missing argument\n");
    return {.status = STATE_ERROR, .output = ""};
  }

  return {.status = STATE_SUCCESS, .output = std::get<std::string>(args[""].data) };
}

successfull_t WriteCommand::execute(std::map<std::string, argumentValue_t> args) {
  if(!args.contains("")) {
    printf("write: missing input\n");
    return {.status = STATE_ERROR, .output = ""};
  }
  if(!args.contains("-o")) {
    printf("write: missing destination\n");
    return {.status = STATE_ERROR, .output = ""};
  }

  std::string text = std::get<std::string>(args[""].data);
  std::string outFile = std::get<std::string>(args["-o"].data);
  std::ofstream out(outFile);

  if(!out) {
    printf("write: Failed to write %ld bytes into %s: Destination does not exists\n", text.length(), outFile.c_str());
    return {.status = STATE_ERROR, .output = ""};
  }
  out << text;
  return {.status = STATE_SUCCESS, .output = "",};
}

successfull_t ListCommand::execute(std::map<std::string, argumentValue_t> args) {
  if(args.size() < 1 || !args.contains("")) {
    printf("list: Invalid Usage. Usage: list <path> <recursive> --type file/dir\n");
    return {.status = STATE_ERROR, .output = ""};
  }
  std::filesystem::path path = std::filesystem::path(std::get<std::string>(args[""].data));
  if(!std::filesystem::exists(path)) {
    printf("list: Path does not exists\n");
    return {.status = STATE_ERROR, .output = ""};
  }

  std::string type = "";
  if(args.contains("-type")) {
    std::string typeValue = std::get<std::string>(args["-type"].data);
    if(typeValue == "file") type = "file";
    if(typeValue == "dir") type = "dir";
  }
  bool recursive = args.contains("recursive");

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
}


