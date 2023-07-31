import subprocess
import os

def walk(dir, endswith=None):
    files = []
    dirs = []
    for file in os.listdir(dir):
        path = dir + "/" + file
        if os.path.isdir(path):
            f, d = walk(path, endswith)
            files.extend(f)
            dirs.extend(d)
            dirs.append(path)
        elif not endswith or path.endswith(str(endswith)):
            files.append(path)
    return files, dirs

files, dirs = walk(os.path.join(os.environ["SRC"], "src"))

for d in dirs:
    d = d.replace(os.path.join(os.environ["SRC"], "src") + "/", "")
    subprocess.call(["mkdir", "-p", os.path.join(os.environ["TARGET"], d)])



subprocess.call(["printf", "[  \033[1;92mOK\033[0;39m  ] generated\n"])
