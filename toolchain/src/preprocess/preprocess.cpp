#include "preprocess.h"

successfull_t preprocess(std::string inFile, std::unordered_map<std::string, std::string> defines, std::filesystem::path baseDir) {
  if(inFile.substr(0, 2) == "./") inFile = inFile.substr(2, inFile.length());

  std::filesystem::path currentFile = baseDir / std::filesystem::path(inFile);
  std::ifstream in(currentFile);

  if(!in.good()) {
    printf("preprocess: Cannot open File %s\n", currentFile.c_str());
    return {
      .status = STATE_ERROR,
      .output = "",
    };
  }
  
  std::string result = "";

  std::string line;
  while(std::getline(in, line)) {
    std::string trimmed = trim(line);
    if(trimmed.substr(0, 3) == "--#") {
      std::string command = untilSpace(trimmed);
      if(command == "--#include") {
        std::string file = trimmed.substr(10, trimmed.length());
        
        file = trim(file);
        if(file.front() == '"') file = file.substr(1, file.length());
        if(file.back() == '"') file.pop_back();

        successfull_t included = preprocess(file, defines, currentFile.parent_path());
        if(included.status == STATE_SUCCESS) {
          result.append("\n");
          result.append(included.output);
        } else {
          printf("preprocess: Error in --#include\n");
          return {
            .status = STATE_ERROR,
            .output = "",
          };
        }
      }
    } else {
      result.append(line);
      continue;
    }
  }

  in.close();
  result.append("\n");
  return {
    .status = STATE_SUCCESS,
    .output = result,
  };
}
