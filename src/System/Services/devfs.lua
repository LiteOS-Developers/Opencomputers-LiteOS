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
        local pos = #proxy.handles + 1
        local value = {device=name}
        proxy.handles[pos] = value
        -- k.write(dump(pos))
        if pos == 10 then
        end
        if proxy.handles[pos] == nil then
            k.write(dump(proxy.handles[pos] == nil))
            k.panic("Device " .. tostring(pos) .. " not opened correctly")
        end
        return pos
    end
    proxy.ensureOpen = function(handle)
        checkArg(1, handle, "number")
        -- k.write("ensureOpen " .. tostring(tonumber(handle)))
        -- error("1")
        if type(proxy.handles[handle]) ~= "table" then
            k.write("34 is true " .. dump(handle))
            return false
        end 
        return proxy.handles[handle].closed ~= true
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
        if proxy.ensureOpen(handle) then
            proxy.handles[handle].closed = true
        end
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
        

        if not proxy.ensureOpen(handle) then
            k.write(tostring(handle) .. " " .. method .. " " .. dump(table.pack(...)) .. " " .. dump(proxy.handles[handle]))
            k.panic("Handle is not open")
            return {}
        end
        local r = proxy.devices[proxy.handles[handle].device][method](...)
        
        return r
    end
    proxy.getAPI = function(handle)
        checkArg(1, handle, "number")
        if not proxy.ensureOpen(handle) then return nil end

        return proxy.devices[proxy.handles[handle].device]
    end

    -- Maps device {name} to {target} (Creates an Alias {target} for {name})
    proxy.mapDevice = function(target, name)
        checkArg(1, name, "string", "nil")

        if name == nil then
            proxy.devices[target] = nil
        end
        local old = proxy.devices[target]
        proxy.devices[target] = proxy.devices[name]
        return old
    end
    return proxy
end
return devfs