k.write("Loading Libraries...")

_G.package = k.system.executeFile("/System/Lib/Package.lua")
package.addLibraryPath("/System/Lib/?.lua")
package.addLibraryPath("/System/Lib/?/init.lua")
_G.require = package.require
_G.threading = k.system.executeFile("/System/Kernel/threading.lua")

_G.event = require("Event")

k.write("Loaded Libraries")
