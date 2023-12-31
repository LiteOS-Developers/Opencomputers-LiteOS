import os

from lfs.create import Create
from lfs.open import Open
from lfs.LFSDriver import LFSDriver, Permission

def fGetContent(filename) -> str:
    with open(filename, "r") as f:
        return f.read()

vfs = Create(133)
vfs.create()
vfs.save("kernel")

fs = Open("kernel")
fs.read()
fs.createPartitionEntry("boot", 128, LFSDriver.DRIVER_NUM, 0x05)
fs.read()
driver = fs.driver("boot")
driver.create()
driver.save()
driver.read()
for filename in os.listdir("./src/System/Kernel"):
    if os.path.isdir(filename): continue
    if not filename.endswith(".lua"): continue
    print(f"[Kernel] {filename}")
    driver.createFile(filename, Permission(0, 0))
    data = fGetContent("./src/System/Kernel/" + filename) #.encode("utf-8")
    driver.writeFile(filename, data)

driver.mkdir("modules", Permission(0, 0))

for filename in os.listdir("./src/System/Kernel/modules"):
    if os.path.isdir(filename): continue
    if not filename.endswith(".lua"): continue
    print(f"[Kernel] modules/{filename}")
    driver.createFile("modules/" + filename, Permission(0, 0))
    data = fGetContent("./src/System/Kernel/modules/" + filename) #.encode("utf-8")
    driver.writeFile("modules/" +filename, data)


print(driver.list("/"))

driver.save()



