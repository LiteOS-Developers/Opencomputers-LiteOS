k.printk(k.L_INFO, " - 10_libraries")


k.package = k.system.executeFile("/lib/Package.lua")
k.package.addLibraryPath("/lib/?.lua")
k.package.addLibraryPath("/lib/?/init.lua")
_G.require = k.package.require
k.threading = k.system.executeFile("/System/Kernel/threading.lua")

k.event = require("Event")
