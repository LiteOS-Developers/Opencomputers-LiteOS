SRC = "./src"
DST = "./build"
FILE = $(echo test) abc

step "preprocess" {
 
  echo Normal: $(list build)
  echo Recursive: $(list build true)
  echo Non-Recursive: $(list build false)
  echo Recursive/File: $(list build true file)
  echo Non-Recursive/File: $(list build false file)
  echo Recursive/Dir: $(list build true dir)
  echo Non-Recursive/Dir: $(list build false dir)
  write $(preprocess $SRC/main.lua) $DST/kernel.lua
}

finish
