_G.VERSION_INFO = {}
_G.VERSION_INFO.major = 0
_G.VERSION_INFO.minor = 1
_G.VERSION_INFO.micro = 0
_G.VERSION_INFO.release = "dev"

k = {}
lib.loadfile("/System/bin/init.lua")()
-- error(computer.uptime())

computer.pullSignal(0)
local result
local event = require("Event")
-- thread management (look in /System/Kernel/threading.lua)
while true do
    for thread, v in pairs(k.threading.threads) do
        if k.threading.threads[thread].stopped then goto continue end
        if coroutine.status(v.coro) == "dead" then
            k.threading.threads[thread]:stop()
            goto continue
        end
        result = table.pack(coroutine.resume(v.coro))
        if not result[1] then
            k.write(dump(result[2]))
        end
        if coroutine.status(v.coro) == "dead" then
            k.threading.threads[thread].result = result[2]
            k.threading.threads[thread]:stop()
            goto continue
        end
        if result[2] == "syscall" then
            result = table.pack(coroutine.resume(v.coro, table.unpack({k.processSyscall(result)})))
        end
        ::continue::
        event.fetch()
    end
end