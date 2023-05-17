

_G.lib.loadfile("/System/Kernel/stdlib.lua")()



k.printk(k.L_INFO, " - 00_Base")


function k.scall(func, ...)
    checkArg(1, func, "function")
    local c = coroutine.create(func)
    local result = table.pack(coroutine.resume(c, ...))
    local ok = result[1]
    table.remove(result, 1)
    return ok, result[1]
end

k.panic = function(e)

    k.printk(k.L_EMERG, "#### stack traceback ####")

    for line in e:gsub("\t", "    "):gmatch("[^\n]+") do
        if line ~= "stack traceback:" then
            k.printk(k.L_EMERG, "%s", line)
        end
    end

    k.printk(k.L_EMERG, "#### end traceback ####")
    k.printk(k.L_EMERG, "kernel panic - not syncing")
    while true do coroutine.yield() end
end
