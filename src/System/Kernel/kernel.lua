_G.VERSION_INFO = {}
_G.VERSION_INFO.major = 0
_G.VERSION_INFO.minor = 1
_G.VERSION_INFO.micro = 0
_G.VERSION_INFO.release = "dev"


k = {screen={}}


for _,file in ipairs(component.invoke(computer.getBootAddress(), "list", "/System/Kernel/modules")) do
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

-- k.threading.createThread("shell", function()
    local shell = k.system.executeFile("/System/Lib/Shell.lua").create("/")
    --[[shell:createDevice("tty0")
    shell:mapToTTY()
    repeat
        shell:execute("/Bin/shell.lua", {"--shell", "tty0"})
        coroutine.yield()
    until false]]
    -- k.write("OS Running")
-- end):start()

-- error(dump(k.threading.threads))
-- thread management (look in /System/Kernel/threading.lua)
while true do
    for thread, v in pairs(k.threading.threads) do
        if coroutine.status(v.coro) == "dead" then
            -- if k.threading == nil then error(k) end
            k.threading.threads[thread]:stop()
            -- _G.write("DEAD: " .. k)
            goto continue
        end
        result = table.pack(coroutine.resume(v.coro))
        if result[1] == true and result.n >= 3 then
            if result[2] == "syscall" then
                local call = result[3]
                local data = result[4] or {}
                coroutine.resume(v.coro, table.unpack(k.processSyscall(call, data)))
            end
        end
        ::continue::
    end
    s = table.pack(computer.pullSignal(0.01))
    if s.n > 0 then
        computer.pushSignal(table.unpack(s))
    end
end
