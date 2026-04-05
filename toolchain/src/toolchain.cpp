#include <iostream>
#include <fstream>
#include <sstream>
#include <unordered_map>
#include <vector>
#include <regex>
#include <cstdlib>
#include <string>

#include "./substitude.h"
#include "./common.h"
#include "./command.h"
#include "./runCommand.h"

std::unordered_map<std::string, std::string> globals;

#if 0
// Run shell command and capture output
std::string execCommand(const std::string& cmd) {
  std::string result;
  char buffer[128];
  // hier ansetzen für eine toolchain nach meinen vorstellungen
  FILE* pipe = popen(cmd.c_str(), "r");
  if (!pipe) return "";

  while (fgets(buffer, sizeof(buffer), pipe)) {
    result += buffer;
  }

  pclose(pipe);
  return result;
}
#endif

int main(int argc, char* argv[]) {
  if(argc != 2) {
    printf("Usage: toolchain <build.script>\n");
    return -1;
  }
  std::ifstream in(argv[1]);
  if (!in.good()) {
    printf("Cannot find file %s\n", argv[1]);
    return -1;
  }

  std::string line;

  bool inStep = false;
  std::unordered_map<std::string, std::string> locals;
 
  while (std::getline(in, line)) {
    line = trim(line);
    if (line.empty()) continue;

    // Finish
    if (line == "finish") break;

    // Global variable
    if (!inStep && line.find('=') != std::string::npos) {
      auto pos = line.find('=');
      std::string key = trim(line.substr(0, pos));
      std::string value = trim(line.substr(pos + 1));

      // Remove quotes
      if (value.front() == '"' && value.back() == '"') {
        value = value.substr(1, value.size() - 2);
      }

      globals[key] = value;
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
        if(runCommand(line, locals, globals).status == STATE_ERROR) break;
      }
    }
  }

  in.close();
  return 0;
}
