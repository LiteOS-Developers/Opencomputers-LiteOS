import os, os.path
import sys
import subprocess
import shutil
import pathlib

if os.name == "posix":
    py = "python3"
elif os.name == "nt":
    py = "python"
else:
    assert False

REPOS = [
    "bootloader", "kernel", "coreutils", "liblua",
    "generated", "kinit"
]

def build(repo, base):
    os.environ["SRC"] = os.path.join(base, repo)
    if 'build.py' in os.listdir(repo):
        subprocess.call([py, os.path.join(repo, 'build.py')])
    elif 'build.sh' in os.listdir(repo):
        subprocess.call([os.path.join(base, repo, 'build.sh')])
    else:
        raise Exception("No build file for repo '%s'" % repo)

if __name__ == "__main__":
    base = os.path.abspath(__file__)
    base = os.path.sep.join(os.path.dirname(base).split(os.path.sep)[:-1])

    os.environ["TARGET"] = os.path.join(base, "build")
    os.environ["BASE"] = base

    if len(sys.argv) >= 2:
        args = sys.argv[1:]
        for arg in args:
            if arg in REPOS:
                build(arg, base)
            else:
                print("No repo '%s' found" % arg)
                sys.exit(1)
        sys.exit(0)

    if os.path.isdir("build"):
        shutil.rmtree("build")
    os.mkdir("build")


    for repo in REPOS:
        build(repo, base)
        