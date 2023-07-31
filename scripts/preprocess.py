import os.path
import re
import io


class PreProcessor:
    def __init__(self, infile, outfile) -> None:
        if isinstance(infile, str):
            if not os.path.isfile(infile):
                raise FileNotFoundError(infile)

            infile = open(infile, "r")
            
        if isinstance(outfile, str):
            outfile = open(outfile, "w")

        self.infile = infile
        self.outfile = outfile
        self.defines = {}
    
    def process(self):
        skip = False
        for line in self.infile.readlines():
            if line.endswith("\n"): line = line[:-1]
            if len(line) == 0: continue

            """if result := re.match("--#define([\s]+)([A-Za-z][\w\d]+)([\s]+)([\w\s\d()+\-\*/,]+)", line.strip()):
                self.defines[result.groups()[1]] = result.groups()[3]
            el"""
            if result := re.match("--#define([\s]+)([A-Za-z][\w\d]+)", line.strip()):
                self.defines[result.groups()[1]] = True
                continue
            if result := re.match(r"--#undef([\s]+)([A-Za-z][\w\d]+)", line.strip()):
                self.defines[result.groups()[1]] = False
            elif result := re.match(r"--#ifdef([\s]+)([A-Za-z][\w\d]+)", line.strip()):
                if not self.defines.get(result.groups()[1]):
                    skip = True
            elif result := re.match(r"--#ifndef([\s]+)([A-Za-z][\w\d]+)", line.strip()):
                if self.defines.get(result.groups()[1]):
                    skip = True
            elif result := re.match(r"--#include([\s]+)\"([\w\/.]+)\"", line):
                buf = io.StringIO()

                p = self.__class__.__new__(self.__class__)
                p.infile = open(result.groups()[1], "r")
                p.outfile = buf
                p.defines = self.defines
                p.process()
                print(buf.getvalue(), file=self.outfile)
            elif result := re.match(r"--#nl", line.strip()):
                print("", file=self.outfile)
            elif result := re.match(r"--#endif", line.strip()):
                skip = False
            elif not skip:
                print(line, file=self.outfile)


if __name__ == "__main__":
    import sys
    args = sys.argv[1:]
    if len(args) >= 2:
        infile = args[0]
        outfile = args[1]

    p = PreProcessor(infile, outfile)
    p.process()
    p.outfile.close()