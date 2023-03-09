local api = {}
local fs = require("Service").getService("filesystem")

api.shutdown = function(...)
    computer.shutdown(false)
end

api.reboot = function(...)
    computer.shutdown(true)
end

api.isFile = function(dir)
    return fs.isFile(dir)
end
api.isDirectory = function(dir)
    return fs.isDirectory(dir)
end
api.fdopen = function(path, mode)
    return fs.open(path, mode)
end
api.fdListDir = function()
    return fs.listDir(dir)
end
api.fdSize = function(file)
    return fs.getFilesize(file)
end
api.fdLastEdit = function(file)
    return fs.getLastEdit(file)
end
api.getDevice = function(name)
    local dev = _G.devices[name]
    -- _G.write("getDevice(" .. dump(name) .. "): " .. dump(table.keys(_G.devices)) .. " " .. dump(dev))
    return dev
end
api.addDevice = function(data)
    _G.write("Creating Device " .. data[1] .. "")
    _G.devices[data[1]] = data[2]
    -- _G.write("result: " .. dump(_G.devices[data[1]]))
end

return api