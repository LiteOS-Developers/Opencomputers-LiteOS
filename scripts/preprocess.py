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
        skip_n = 0
        for line in self.infile.readlines():
            if line.endswith("\n"): line = line[:-1]
            if len(line) == 0: continue
            if skip_n > 0:
                skip_n -= 1
                continue

            """if result := re.match("--#define([\s]+)([A-Za-z][\w\d]+)([\s]+)([\w\s\d()+\-\*/,]+)", line.strip()):
                self.defines[result.groups()[1]] = result.groups()[3]
            el"""
            if (result := re.match("--#define([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                self.defines[result.groups()[1]] = True
                continue
            if (result := re.match(r"--#undef([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                self.defines[result.groups()[1]] = False
            elif (result := re.match(r"--#ifdef([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                if not self.defines.get(result.groups()[1]):
                    skip = True
            elif (result := re.match(r"--#ifndef([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                if self.defines.get(result.groups()[1]):
                    skip = True
            elif (result := re.match(r"--#include([\s]+)\"([\w\/.]+)\"", line.strip())) and not skip:
                buf = io.StringIO()

                p = self.__class__.__new__(self.__class__)
                p.infile = open(result.groups()[1], "r")
                p.outfile = buf
                p.defines = self.defines
                p.process()
                print(buf.getvalue(), file=self.outfile)
            elif result := re.match(r"--#nl", line.strip()) and not skip:
                print("", file=self.outfile)
            elif (result := re.match(r"--#skip([\s]+)([\d]+)", line.strip())) and not skip:
                skip_n = int(result.groups()[1])
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

    cwd = os.getcwd()

    base = os.path.dirname(os.path.abspath(infile))
    
    os.chdir(base)
    p = PreProcessor(infile, outfile)
    p.process()
    p.outfile.close()
    os.chdir(cwd)