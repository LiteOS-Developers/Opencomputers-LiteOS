_G.VERSION_INFO = {}
_G.VERSION_INFO.major = 0
_G.VERSION_INFO.minor = 1
_G.VERSION_INFO.micro = 0
_G.VERSION_INFO.release = "dev"

k = {}
lib.loadfile("/sbin/init.lua")()
-- error(computer.uptime())

computer.pullSignal(0)
local result
local event = require("Event")
-- thread management (look in /System/Kernel/threading.lua)
while true do
    
end