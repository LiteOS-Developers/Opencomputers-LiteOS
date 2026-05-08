#include "./command.h"

PreprocessCommand::PreprocessCommand() {
  m_name = "preprocess";
  m_arguments = std::map<std::string, ArgumentValueType>{{ "-D", ARGUMENT_VALUE_FLAG_VALUE}, {"", ARGUMENT_VALUE_VALUE}};
}

successfull_t PreprocessCommand::execute(std::map<std::string, argumentValue_t> args) {
  if(!args.contains("")) {
    printf("preprocess: missing input file");
    return {.status = STATE_ERROR, .output = ""};
  }
  return preprocess(std::get<std::string>(args[""].data), std::unordered_map<std::string, std::string>(), std::filesystem::current_path());
}
