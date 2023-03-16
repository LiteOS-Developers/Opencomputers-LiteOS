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

k.write("Running CoreOS v" .. _G.VERSION_INFO.major .. "." .. _G.VERSION_INFO.minor .. "." .. _G.VERSION_INFO.micro .. "-".. _G.VERSION_INFO.release)

k.threading.createThread("ProcessDeamon", function()
    while true do
        coroutine.yield()
    end
end):start()

local function parseError(...)
    local v = table.pack(...)
    local ok = v[1]
    local err = v[2]
    -- k.write("33: " .. dump(v))
    
    if ok then
        -- k.write("OK")
        return {err, nil}
    end
    return {nil, err}
end

local function callSecure(fnc, ...)
    local ok, err = xpcall(fnc, debug.traceback, ...)
    return table.unpack(parseError(ok, err))
end

-- k.write(dump(k.filesystem.listDir("/dev")))

k.threading.createThread("shell", function()
    local builtins = require("Sandbox").builtins
    _G.syscall = builtins.syscall
    _G.ioctl = builtins.ioctl

    local shell = require("Shell")
    
    local sh, err
    local sh, err = callSecure(shell.connect, "tty0")
    if not sh then
        error(err)
    end
    local result, err = callSecure(sh.execute, sh, "/Bin/shell.lua")
    k.write(dump(err))
    if type(result) == nil then
        k.panic(err)
    end
    k.write("Result: " .. dump(result))
    sh:close()

    _G.syscall, _G.ioctl = nil, nil
end):start()

-- thread management (look in /System/Kernel/threading.lua)
while true do
    for thread, v in pairs(k.threading.threads) do
        if coroutine.status(v.coro) == "dead" then
            -- if k.threading == nil then error(k) end
            k.threading.threads[thread]:stop()
            -- _G.write("DEAD: " .. k)
            goto continue
        end
        result = table.pack(pcall(coroutine.resume, v.coro))
        if not result[1] then
            table.remove(result, 1)
            k.panic(table.concat(result, " "))
        end
        table.remove(result, 1)
        if result[1] == true and result.n >= 3 then
            if result[2] == "syscall" then
                local call = result[3]
                local r = result
                table.remove(r, 1)
                table.remove(r, 1)
                table.remove(r, 1)
                r.n = nil
                local data = r

                local result, e = k.processSyscall(call, data)
                coroutine.resume(v.coro, result, e)
            end
        end
        ::continue::
    end
    s = table.pack(computer.pullSignal(0.01))
    if s.n > 0 then
        computer.pushSignal(table.unpack(s))
    end
end
