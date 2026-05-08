#include "./echo.h"
#include "./write.h"

EchoCommand::EchoCommand() {
  m_name = "echo";
  m_arguments = std::map<std::string, ArgumentValueType>{{"",ARGUMENT_VALUE_ALL}};
}

WriteCommand::WriteCommand() {
  m_name = "write";
  m_arguments = std::map<std::string, ArgumentValueType>{{"", ARGUMENT_VALUE_VALUE}, {"-o", ARGUMENT_VALUE_FLAG_VALUE}};
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
