local devfs = {}
local uuid = _G.lib.loadfile("/Lib/uuid.lua")()

devfs.create = function()
    local proxy = {}
    proxy.addr = uuid.next()
    proxy.devices = {}
    proxy.handles = {}

    proxy.spaceUsed = function()
        return 0
    end
    proxy.open = function(file, mode)
        checkArg(1, file, "string")
        checkArg(1, mode, "string")

        local name = string.sub(file, 2, string.len(file))
        table.insert(proxy.handles, {device=name})
        return #proxy.handles
    end
    proxy.seek = function(handle, wh, off)
        error("Devices doesn't support seek")
    end
    proxy.makeDirectory = function(path)
        error("Devices doesn't support directories")
    end
    proxy.exists = function(path)
        -- error("exists: " .. dump(proxy.devices[string.sub(path, 2)]))
        return proxy.devices[string.sub(path, 2)] ~= nil
    end
    proxy.isReadOnly = function()
        return true
    end
    proxy.write = function(handle, buf)
        error("Devices doesn't support write")
    end
    proxy.spaceTotal = function()
        return 0
    end
    proxy.isDirectory = function(file)
        return false
    end
    proxy.rename = function(old, new)
        error("Devices are readonly")
    end
    proxy.list = function(path)
        return table.keys(proxy.devices)
    end
    proxy.lastModified = function(path)
        return 0
    end
    proxy.getLabel = function()
        return "devfs"
    end
    proxy.remove = function(file)
        error("Device doesn't support remove")
    end
    proxy.close = function(handle)
        proxy.handles[handle] = nil
    end
    proxy.size = function()
        return 0
    end
    proxy.read = function(handle, count)
        error("Devices doesn't support read")
    end
        
    proxy.register = function(name, api)
        checkArg(1, name, "string")
        checkArg(2, api, "table")
        proxy.devices[name] = api
    end

    proxy.ioctl = function(handle, method, ...)
        checkArg(1, handle, "number")
        checkArg(2, method, "string")

        return proxy.devices[proxy.handles[handle].device][method](...)
    end
    proxy.getAPI = function(handle)
        checkArg(1, handle, "number")
        return proxy.devices[proxy.handles[handle].device]
    end
    return proxy
end
return devfs