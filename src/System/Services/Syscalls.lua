local api = {}
local fs = k.service.getService("filesystem")

api.shutdown = function(...)
    computer.shutdown(false)
end
api.reboot = function(...)
    computer.shutdown(true)
end

api.resetCursor = function(args)
    _G.screen.x = args[1] or 1
    _G.screen.y = args[2] or 1
end

api.isFile = function(dir)
    return fs.isFile(dir)
end
api.isDirectory = function(dir)
    return fs.isDirectory(dir)
end
api.fopen = function(file, mode)
    return fs.open(file, mode)
end
api.fdread = function(handle, size)
    return fs.read(handle, size)
end
api.fdwrite = function(handle, buf)
    return fs.write(handle, buf)
end
api.fdseek = function(handle, _whence, off)
    return fs.seek(handle, _whence, off)
end
api.fdclose = function(handle)
    return fs.close(handle)
end

api.fListDir = function(dir)
    return table.pack(fs.listDir(dir))
end
api.fSize = function(file)
    return fs.getFilesize(file)
end
api.fLastEdit = function(file)
    return fs.getLastEdit(file)
end

api.ioctl = function(handle, func, ...)
    checkArg(1, handle, "number")
    checkArg(2, func, "string")
    -- k.write("51: " .. func .. ": " .. dump(k.devices.devices[k.devices.handles[fs.getRealHandle(handle)].device]))
    return k.devices.ioctl(fs.getRealHandle(handle), func, ...)
end
api.ensureOpen = function(handle)
    return fs.ensureOpen(handle)
end
--[[
api.getDevice = function(name)
    -- _G.write("getDevice(" .. name .. "): " .. dump(_G.devices[name]))
    local handle, err = fs.open("/dev/" .. name, "r")
    if handle == nil then return {} end
    return _G.devices.getAPI(handle)
end
api.addDevice = function(args)
    _G.devices.register(args[1], args[2])
end
api.mapDevice = function(args)
    -- _G.write(dump(args))
    checkArg(1, args[1], "string")
    checkArg(2, args[2], "string")
    
    _G.devices.register(args[2], _G.devices[args[1])
    
    end
]]
api.filterDevices = function(name)
    local length = string.len(name)
    local result = {}
    for i, n in pairs(table.keys(_G.devices.devices)) do
        if n:sub(1, length) == name then
            table.insert(result, n)
        end
    end
    return table.pack(result)
end

return api