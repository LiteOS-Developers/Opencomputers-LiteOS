import os, os.path
import sys
import subprocess
import shutil
import pathlib
import threading as th

if os.name == "posix":
    py = "python3"
elif os.name == "nt":
    py = "python"
else:
    assert False

base = os.path.abspath(__file__)
base = os.path.sep.join(os.path.dirname(base).split(os.path.sep)[:-1])

REPOS = [
    "bootloader", "kernel", "coreutils", "liblua",
    "generated", "kinit", "devtab"
]
env = lambda repo : [f'TARGET="{base}/{repo}/build"', f'BASE="{base}"', f'SRC="{base}/{repo}"']

def build(repo, base):
    subprocess.call(["rm", "-rf", f"{base}/{repo}/build"])
    print(f"[CLEAN] {repo}")
    if 'Makefile' in os.listdir(repo):
        print(f"[BUILD] {repo}")
        subprocess.run(["make", "--no-print-directory", "-C", repo, "build", *env(repo)])
        print(f"[INSTALL] {repo}")
        subprocess.run(["cp", "-a", f"{base}/{repo}/build/.", f"{base}/build"])
    else:
        raise Exception("No build file for repo '%s'" % repo)

def buildAll(args):
    tasks:list[th.Thread] = []
    for arg in args:
        if arg in REPOS:
            thread = th.Thread(target=build, args=(arg, base))
            thread.start()
            tasks.append(thread)
        else:
            print("No repo '%s' found" % arg)
            sys.exit(1)
    _ = [t.join() for t in tasks]
    sys.exit(0)

if __name__ == "__main__":
    os.environ["TARGET"] = os.path.join(base, "build")
    os.environ["BASE"] = base

    if len(sys.argv) >= 2:
        args = sys.argv[1:]
        buildAll(args)

    if os.path.isdir("build"):
        shutil.rmtree("build")
    os.mkdir("build")
    
    buildAll(REPOS)
        