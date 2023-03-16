k.write("Booting...")

k.write("Initalizing System Services...")

k.service = _G.lib.loadfile("/System/Lib/Service.lua")()
k.system = _G.lib.loadfile("/System/Lib/System.lua")()


k.write("  - Filesystem")
local err
k.filesystem, err = k.service.getService("filesystem")
_G.component = _G.lib.loadfile("/System/Kernel/components.lua")()

k.write("  - Device management")
local dev = k.devices
k.devfs = k.service.getService("devfs")
res, err = pcall(k.devfs.create)
if not res then
    k.panic(err)
end
k.devices = err
k.devices.register("gpu", dev.gpu)


function k.write(msg, newLine)
    msg = msg == nil and "" or msg
    newLine = newLine == nil and true or newLine

    local gpu = k.devices.open("/gpu", "r")
    if gpu then
        local sw, sh = k.devices.ioctl(gpu, "getResolution")
        -- error(tostring(sw) .. " " .. tostring(sh))

        k.devices.ioctl(gpu, "set", k.screen.x, k.screen.y, msg)
        -- while true do computer.pullSignal() end

        if k.screen.y == sh and newLine == true then
            k.devices.ioctl(gpu, "copy", 1, 2, sw, sh - 1, 0, -1)
            k.devices.ioctl(gpu, "file", 1, sh, sw, 1, "")
            -- k.devices.gpu.copy(1, 2, sw, sh - 1, 0, -1)
            -- k.devices.gpu.fill(1, sh, sw, 1, " ")
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

-- k.write("TEST")
