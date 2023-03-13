k.write("Booting...")
k.write("Initalizing System Services...")

k.service = _G.lib.loadfile("/System/Lib/Service.lua")()
k.system = _G.lib.loadfile("/System/Lib/System.lua")()

k.write("  - Loading Filesystem Service...")
k.filesystem = _G.k.service.getService("filesystem")
k.write("  - Loaded Filesystem Service")
