_G.VERSION_INFO = {}
_G.VERSION_INFO.major = 0
_G.VERSION_INFO.minor = 1
_G.VERSION_INFO.micro = 0
_G.VERSION_INFO.release = "dev"


k = {screen={}}

local files = component.invoke(computer.getBootAddress(), "list", "/System/Kernel/modules")
table.sort(files)

for _,file in ipairs(files) do
    local module, err = _G.lib.loadfile("/System/Kernel/modules/" .. file)
    if not module then
        error(err)
    end
    module()
end

k.printk(k.L_INFO, "Running CoreOS v" .. _G.VERSION_INFO.major .. "." .. _G.VERSION_INFO.minor .. "." .. _G.VERSION_INFO.micro .. "-".. _G.VERSION_INFO.release)

local t = function()
    while true do
        coroutine.yield()
    end
end
-- k.threading.createThread("ProcessDeamon-1", t):start()
-- k.threading.createThread("ProcessDeamon-2", t):start()


local function parseError(...)
    local v = table.pack(...)
    local ok = v[1]
    local err = v[2]
    
    if ok then
        return {err, nil}
    end
    return {nil, err}
end


k.threading.createThread("init", function() 
    local sandbox = require("Sandbox")
    local env = sandbox.create_env({
        perm_check = false
    })
    _G.syscall = env.syscall
    _G.ioctl = env.ioctl

    local shell = require("Shell")
    
    local sh, err
    _G.filesystem = env.filesystem
    local sh, err = shell.connect("tty0")
    if not sh then
        k.panic(err)
    end
    -- while true do
        sh:execute("/Bin/shell.lua")
    -- end
    -- k.panic(result)


    _G.syscall, _G.ioctl = nil, nil
end, 1):start()

-- k.threading.createThread("drive-test", function()
--     local drives = require("Drives")
--     addr = component.list("drive")()
--     component.invoke(addr, "writeSector", 1, string.rep("\0", 512))
--     component.invoke(addr, "writeSector", 2, string.rep("\0", 512))
--     component.invoke(addr, "writeSector", 3, string.rep("\0", 512))
--     drives.createLPT(addr)
--     drives.createPartition(addr, "boot", 10, 0x01, 3, 1)
--     drives.createPartition(addr, "data", 30, 0, 13, 1)
--     drives.createPartition(addr, "cfg", 20, 0, 43, 1)
--     drives.createPartition(addr, "swap", 15, 0x02, 63, 2)
--     k.write(dump(drives.getNextFreeSector(addr, 10)))
-- end, 1)


-- k.threading.createThread("init-3", function()
--     local drives = require("Drives")
--     addr = component.list("drive")()
--     -- local parts = drives.read(addr).partitions
--     -- for _, v in ipairs(parts) do
--     --     k.write(dump(v))
--     -- end
-- end, 1):start()


local result
-- thread management (look in /System/Kernel/threading.lua)
while true do
    for thread, v in pairs(k.threading.threads) do
        if k.threading.threads[thread].stopped then goto continue end
        if coroutine.status(v.coro) == "dead" then
            k.threading.threads[thread]:stop()
            goto continue
        end
        result = table.pack(coroutine.resume(v.coro))
        -- k.write(dump(result))
        if not result[1] then
            k.write(dump(result[2]))
        end
        -- k.write(dump(result))
        if coroutine.status(v.coro) == "dead" then
            k.threading.threads[thread].result = result[2]
            k.threading.threads[thread]:stop()
            goto continue
        end
        if result[2] == "syscall" then
            -- k.printk(k.L_INFO, dump(result))
            result = table.pack(coroutine.resume(v.coro, table.unpack({k.processSyscall(result)})))
            -- k.printk(k.L_WARNING, dump(result))
        end
        ::continue::
        local s = table.pack(computer.pullSignal(0.01))
        if s.n > 0 then
            computer.pushSignal(table.unpack(s))
        end
    end
end