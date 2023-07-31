#! /bin/bash
mkdir -p $TARGET/boot


if python3 $BASE/scripts/preprocess.py $SRC/src/main.lua $TARGET/boot/kernel.lua; then
    printf "[  \033[1;92mOK\033[0;39m  ] Kernel\n"
else
    rm $TARGET/boot/kernel.lua
fi
