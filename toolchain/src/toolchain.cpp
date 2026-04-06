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
  
  if(!runFile(std::string(argv[1]))) return -1;
  return 0;
}


