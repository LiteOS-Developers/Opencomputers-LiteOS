#! /bin/bash
mkdir -p $TARGET/usr
cp -r $SRC/src/lib $TARGET/lib
cp -r $SRC/src/usr/lib $TARGET/usr
printf "[  \033[1;92mOK\033[0;39m  ] corelib\n"
