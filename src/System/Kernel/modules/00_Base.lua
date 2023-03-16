local screen = component.list("screen", true)()
local gpu = screen and component.list("gpu", true)()
k.screen = { y = 1, x = 1 }
k.devices = {}

if gpu then 
    gpu = component.proxy(gpu)

    if gpu then
        if not gpu.getScreen() then 
            gpu.bind(screen)
        end
        local w, h = gpu.getResolution()

        k.screen.w = w
        k.screen.h = h

        gpu.setResolution(w, h)
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, w, h, " ")
        -- _G.k.screen = component.proxy(screen)
        k.devices.gpu = gpu
    end
end
if computer.getArchitecture() ~= "Lua 5.3" then
    error("Failed to Boot: OS requires Lua 5.3")
    _G.computer.shutdown()
end
_G.lib.loadfile("/System/Kernel/stdlib.lua")()

function _G.k.write(msg, newLine)
    msg = msg == nil and "" or msg
    newLine = newLine == nil and true or newLine
    if k.devices.gpu then
        local sw, sh = k.devices.gpu.getResolution() 

        k.devices.gpu.set(k.screen.x, k.screen.y, msg)
        if k.screen.y == sh and newLine == true then
            k.devices.gpu.copy(1, 2, sw, sh - 1, 0, -1)
            k.devices.gpu.fill(1, sh, sw, 1, " ")
        else
            if newLine then
                k.screen.y = k.screen.y + 1
            end
        end
        if newLine then
            k.screen.x = 1
        else
            k.screen.x = k.screen.x + string.len(msg)
        end
    end
end
k.L_EMERG   = 0
k.L_ALERT   = 1
k.L_CRIT    = 2
k.L_ERROR   = 3
k.L_WARNING = 4
k.L_NOTICE  = 5
k.L_INFO    = 6
k.L_DEBUG   = 7
k.cmdline = {}
k.cmdline.loglevel = tonumber(k.cmdline.loglevel) or 8

local reverse = {}
for name,v in pairs(k) do
    if name:sub(1,2) == "L_" then
        reverse[v] = name:sub(3)
    end
end

function k.printk(level, fmt, ...)
    local message = string.format("[%08.02f] %s: ", computer.uptime(),
        reverse[level]) .. string.format(fmt, ...)

    if level <= k.cmdline.loglevel then
        k.write(message)
    end

    -- log_to_buffer(message)
  end

k.panic = function(e)

    k.printk(k.L_EMERG, "#### stack traceback ####")

    for line in e:gsub("\t", "    "):gmatch("[^\n]+") do
        if line ~= "stack traceback:" then
            k.printk(k.L_EMERG, "%s", line)
        end
    end

    k.printk(k.L_EMERG, "#### end traceback ####")
    k.printk(k.L_EMERG, "kernel panic - not syncing: %s", reason)
    while true do coroutine.yield() end
end
