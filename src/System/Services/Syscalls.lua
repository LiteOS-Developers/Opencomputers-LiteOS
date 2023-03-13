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
api.fopen = function(args)
    return fs.open(args[1], args[2])
end
api.fdread = function(args)
    return fs.read(args[1], args[2])
end
api.fdwrite = function(args)
    return fs.write(args[1], args[2])
end
api.fdseek = function(args)
    return fs.seek(args[1], args[2], args[3])
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

api.getDevice = function(name)
    -- _G.write("getDevice(" .. name .. "): " .. dump(_G.devices[name]))
    return _G.devices[name]
end
api.addDevice = function(args)
    _G.devices[args[1]] = args[2]
    return _G.devices[args[1]] ~= nil
end
api.mapDevice = function(args)
    -- _G.write(dump(args))
    checkArg(1, args[1], "string")
    checkArg(2, args[2], "string")
    
    _G.devices[args[2]] = _G.devices[args[1]]
    -- _G.write(dump(_G.devices[args[2]]))
end
api.filterDevices = function(name)
    local length = string.len(name)
    local result = {}
    for i, n in pairs(table.keys(_G.devices)) do
        if n:sub(1, length) == name then
            table.insert(result, n)
        end
    end
    return table.pack(result)
end

return api