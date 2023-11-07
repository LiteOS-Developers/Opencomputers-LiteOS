from lfs import LFSDriver
from lfs.shell import editor

import os.path as path

def savefile(vfs:LFSDriver, filepath:str, lines:list[str]):
    content = "\n".join(lines).encode("utf-8")
    vfs.writeFile(filepath, content)

class LFSCmd:
    def __init__(self, driver, filename):
        self.driver:LFSDriver = driver
        self.driver.read()
        self.filename = filename

    def execute(self, partName):
        curdir = "/"
        while True:
            value = input(f'{partName}@{path.basename(self.filename)} {curdir}> ').strip()
            cmd = value.split(" ")[0]
            args = value.split(" ")[1:]

            match cmd:
                case 'list' | 'ls':
                    files = self.driver.list(curdir)
                    for filename in files:
                        print(filename)
                case 'cd':
                    if len(args) > 0:
                        parts = args[0].split("/")
                        if args[0] == '/':
                            curdir = "/"
                            continue
                        for p in parts:
                            if p == "..":
                                curdir = '/'.join(curdir)[:-1]
                            else:
                                curdir += "/" + p
                    else:
                        print(curdir)
                case "edit":
                    if len(args) > 0:
                        if self.driver.isFile(args[0]):
                            entry = self.driver.getEntry(args[0])
                            content = self.driver.readFile(args[0], entry.size).decode("utf-8")
                            lines = content.split("\n")
                            editor.init(lines, lambda l : savefile(self.driver, args[0], l))
                        elif self.driver.isDir(args[0]):
                            print("Target is a Directory")
                        else:
                            print("File not existing")
                    else:
                        print("Not enough Arguments for this command")