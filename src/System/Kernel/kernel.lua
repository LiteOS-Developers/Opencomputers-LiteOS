_G.VERSION_INFO = {}
_G.VERSION_INFO.major = 0
_G.VERSION_INFO.minor = 1
_G.VERSION_INFO.micro = 0
_G.VERSION_INFO.release = "dev"

_G.devices = {}
_G.screen = { y = 1, x = 1 }


local shutdown = computer.shutdown


_G.lib.loadfile("/System/Kernel/prepare.lua")()
f, e = _G.lib.loadfile("/System/Kernel/stdlib.lua")()

_G.write("Booting...")

_G.table.keys = function(table)
    local r = {}
    for k, v in pairs(table) do
        _G.table.insert(r, k)
    end
    return r
end

_G.service = _G.lib.loadfile("/System/Lib/Service.lua")()
_G.system = _G.lib.loadfile("/System/Lib/System.lua")()

_G.write("Loading components...")
_G.component = _G.lib.loadfile("/System/Kernel/components.lua")()

local fs = service.getService("filesystem")

datacard = component.list("data")()
if datacard == nil then
    error("No DataCard Avaiable!")
end
_G.devices.data = component.proxy(datacard)



_G.write("Loaded components")

_G.write("Initalizing System Services...")


_G.write("  - Loading Filesystem Service...")
local filesystem = _G.service.getService("filesystem")
_G.write("  - Loaded Filesystem Service")

_G.write("Mouting filesystems...")

local drive0 = computer.getBootAddress()
_G.devices.drive0 = component.proxy(drive0)
filesystem.mount(computer.getBootAddress(), "/")
local driveId = 1
for addr, type in pairs(component.list("filesystem")) do
    if not addr == drive0 then
        _G.devices["drive"..tostring(driveId)] = component.proxy(addr)
        driveId = driveId + 1
    end
   --filesystem.mount(addr, "/Mount/" .. addr)
end
    

_G.write("Mouted filesystems...")

_G.write("Loading Libraries...")

_G.package = system.executeFile("/System/Lib/Package.lua")
package.addLibraryPath("/System/Lib/?.lua")
package.addLibraryPath("/System/Lib/?/init.lua")
_G.require = package.require
_G.threading = system.executeFile("/System/Kernel/threading.lua")
-- _G.system.users = require("System.Users")

local event = require("Event")
_G.write("Loaded Libraries")

_G.write("Running CoreOS v" .. _G.VERSION_INFO.major .. "." .. _G.VERSION_INFO.minor .. "." .. _G.VERSION_INFO.micro .. "-".. _G.VERSION_INFO.release)

-- hold computers alive 
threading.createThread("Thread-1", function()
    while true do
        system.sleep(0.1)
    end
end):start()


threading.createThread("shell", function()
    local shell = system.executeFile("/System/Lib/Shell.lua").create("/")
    shell:createDevice("tty0")
    shell:mapToTTY()
    repeat
        shell:execute("/Bin/shell.lua", {"--shell", "tty0"})
        coroutine.yield()
    until false
end):start()

_G.keys = {}

--[[event.listen("key_up", function(_, addr, char, code, player)
    if #_G.keys ~= 0 then
        for i, v in pairs(_G.keys) do
            if rmFloat(v.char) == rmFloat(char) and rmFloat(v.code) == rmFloat(code) then
                table.remove(_G.keys, i)
                return
            end
        end
    end
end)
event.listen("key_down", function(_, addr, chr, cd, player) 
    _G.write(utf8.char(chr))
    table.insert(_G.keys, {char=chr, code=cd})
end)]]


local syscalls = service.getService("Syscalls")
    
-- thread management (look in /System/Kernel/threading.lua)
while true do
    for k, v in pairs(threading.threads) do
        if coroutine.status(v.coro) == "dead" then
            threading.threads[k]:stop() -- stop and remove dead threads and then continue
            -- _G.write("DEAD: " .. k)
            goto continue
        end
        result = table.pack(coroutine.resume(v.coro))
        -- _G.write("SWAP: " .. dump(result))
        if result[1] == true and result.n >= 3 then
            if result[2] == "syscall" then
                local call = result[3]
                local data = result[4] or {}
            
                if syscalls[call] ~= nil then
                    -- _G.write(dump(table.unpack(data)))
                    result, err = xpcall(syscalls[call], debug.traceback, data)
                    if not result then
                        coroutine.resume(v.coro, nil, err)
                        goto continue
                    end
                    local r = table.pack(err)
                    coroutine.resume(v.coro, r, err)
                else
                    coroutine.resume(v.coro, nil, "Syscall not found")
                end
            end
        end
        ::continue::
    end
    s = table.pack(computer.pullSignal(0.01))
    if s.n > 0 then
        computer.pushSignal(table.unpack(s))
    end
end
