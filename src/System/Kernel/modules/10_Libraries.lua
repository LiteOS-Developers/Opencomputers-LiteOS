k.printk(k.L_INFO, "Loading Libraries...")

k.package = k.system.executeFile("/System/Lib/Package.lua")
k.package.addLibraryPath("/System/Lib/?.lua")
k.package.addLibraryPath("/System/Lib/?/init.lua")
_G.require = k.package.require
k.threading = k.system.executeFile("/System/Kernel/threading.lua")

k.event = require("Event")
-- error(k.event)

k.printk(k.L_INFO, "Loaded Libraries")
