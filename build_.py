import os, os.path
import shutil, sys

base_dir = os.path.join(os.path.dirname(__file__))
os.chdir(base_dir)


    
def copy(src, target):
    print(f"{src} -> {target}")
    if os.path.isdir(os.path.join(base_dir, src)):
        os.mkdir(target)
        # print(target)
        copyDir(src)
    else:
        shutil.copy2(src, target)

def copyDir(d):
    # print(d)
    for f in os.listdir(d):
        src = os.path.join(d, f)
        target = os.path.join("build", os.sep.join(d.split(os.sep)[1:]) if len(d.split(os.sep)) > 1 else "", f)
        copy(src, target)

def patch():
    print("Patching ...")

    copy("src/bootloader.lua", "build/System/boot.lua")

    if os.path.exists("build/bootloader.lua"):
        os.remove("build/bootloader.lua")
        print("[RM] " + "build/bootloader.lua")
    
    if os.path.isdir("build/System/Kernel"):
        shutil.rmtree( "build/System/Kernel")
        print("[RM] " + "build/System/Kernel")

    os.system("python main.py")
    copy("kernel", "build/System/kernel")

if "--full" in sys.argv:
    if not os.path.isdir("build"):
        os.mkdir("build")
    else:
        print("Deleting and recreating build directory\n")
        if os.path.isdir("build"): shutil.rmtree("build")
        os.mkdir("build")

    copyDir("src")
else:
    if not os.path.isdir("build"):
        print("Build dir not existing...")
        sys.exit()

patch()

