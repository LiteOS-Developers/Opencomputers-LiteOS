#include "substitude.h"

std::string substitute(std::string input, std::unordered_map<std::string, std::string>& locals, std::unordered_map<std::string, std::string>& globals) {
  std::regex var(R"(\$([A-Za-z_][A-Za-z0-9_]*))");
  //std::regex localVar(R"(@([A-Za-z_][A-Za-z0-9_]*))");

  std::smatch match;

  // Globals
  while (regex_search(input, match, var)) {
    std::string key = match[1];
    if(globals.count(key)) {
      std::string value = globals[key];
      input.replace(match.position(0), match.length(0), value);
    } else if (locals.count(key)){
      std::string value = locals[key];    
      input.replace(match.position(0), match.length(0), value);
    }
  }

return input;
}
