SRC = "./src"
DST = "./build"

step "preprocess" {
  write $(preprocess $SRC/main.lua) $DST/kernel.lua
}

finish
