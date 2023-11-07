import os.path
import re
import io
import subprocess

def error(msg):
    subprocess.call(["printf", "[  \033[1;91mERR\033[0;39m ] " + msg + "\n"])

class PreProcessor:
    def __init__(self, infile, outfile, defines:dict[str, True]=None) -> None:
        if isinstance(infile, str):
            if not os.path.isfile(infile):
                raise FileNotFoundError(infile)

            infile = open(infile, "r")
            
        if isinstance(outfile, str):
            outfile = open(outfile, "w")

        defines = defines or {}
        if not isinstance(defines, dict):
            error("`defines` is not an dict. using default (%s) %s" %( infile, defines))
            defines = None

        self.infile = infile
        self.outfile = outfile
        self.defines = defines or {}
    
    def process(self):
        skip = False
        skip_n = 0
        for line in self.infile.readlines():
            if line.endswith("\n"): line = line[:-1]
            if len(line) == 0: continue
            if skip_n > 0:
                skip_n -= 1
                continue

            if (result := re.match("--#define([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                self.defines[result.groups()[1]] = True
                continue
            elif (result := re.match(r"--#undef([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                self.defines[result.groups()[1]] = False
            elif not skip and line.startswith("--#error"):
                line = line[8:]
                error(line.strip())
                raise SystemExit(-1)
                sys.exit(-1)
            elif (result := re.match(r"--#ifdef([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                if not self.defines.get(result.groups()[1]):
                    skip = True
            elif (result := re.match(r"--#ifndef([\s]+)([A-Za-z][\w\d]+)", line.strip())) and not skip:
                if self.defines.get(result.groups()[1]):
                    skip = True
            elif (result := re.match(r"--#include([\s]+)\"([\w\/.]+)\"", line.strip())) and not skip:
                buf = io.StringIO()

                p = self.__class__.__new__(self.__class__)
                try:
                    p.infile = open(result.groups()[1], "r")
                except FileNotFoundError as e:
                    error("FileNotFound: %s" % e.filename)
                    sys.exit(-1)
                p.outfile = buf
                p.defines = self.defines
                p.process()
                self.defines = p.defines
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
        predefs = None
        if len(args) >= 4 and args[2] == "-c" and os.path.isfile(args[3]):
            inbuf = io.StringIO()
            inbuf.write("--#include \"%s\"" % os.path.abspath(args[3]))
            inbuf.seek(0)
            outbuf = io.StringIO()
            defs = PreProcessor(inbuf, outbuf)
            defs.process()
            predefs = defs.defines

    cwd = os.getcwd()

    base = os.path.dirname(os.path.abspath(infile))
    
    os.chdir(base)
    p = PreProcessor(infile, outfile, predefs)
    p.process()
    p.outfile.close()
    os.chdir(cwd)