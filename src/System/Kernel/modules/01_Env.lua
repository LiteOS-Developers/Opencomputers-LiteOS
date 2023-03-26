
-- k.printk(k.L_INFO, "Initalizing System Services...")
k.printk(k.L_INFO, " - 01_env")


k.service = _G.lib.loadfile("/System/Lib/Service.lua")()
k.system = _G.lib.loadfile("/System/Lib/System.lua")()


local err
k.filesystem, err = k.service.getService("filesystem")
_G.component = _G.lib.loadfile("/System/Kernel/components.lua")()

k.gpu = k.devices.gpu
local dev = k.devices
k.devfs = k.service.getService("devfs")
res, err = xpcall(k.devfs.create, debug.traceback)
if not res then
    k.panic(err)
end
k.devices = err
k.devices.register("gpu", dev.gpu)


function k.write(msg, newLine)
    msg = msg == nil and "" or msg
    newLine = newLine == nil and true or newLine

    local gpu = k.gpu
    if gpu then
        local sw, sh = k.gpu.getResolution()
        -- error(tostring(sw) .. " " .. tostring(sh))

        k.gpu.set(k.screen.x, k.screen.y, msg)
        -- while true do computer.pullSignal() end

        if k.screen.y == sh and newLine == true then
            k.gpu.copy(1, 2, sw, sh - 1, 0, -1)
            k.gpu.fill(1, sh, sw, 1, " ")
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

local filesystem = k.filesystem
_G.dofile = function(path, env)
    env = env or _G
    if filesystem.isFile(path) then
        local file = filesystem.open(path, "r")
        local data = ""
        local content
        repeat
            content = filesystem.read(file, math.huge)
            data = data .. (content or "")
        until not content
        filesystem.close(file)
        local _ENV = _G
        _G = env
        local l, e = load(data, "=" .. path, "bt", env)
        if not l then
            _G = _ENV
            return nil, e
        end
        local res = l()
        _G = _ENV
        -- k.write(path .. ": " .. dump(res))
        return res, nil  
    end
    return nil, "File not Found" 
end

-- k.write("TEST")
