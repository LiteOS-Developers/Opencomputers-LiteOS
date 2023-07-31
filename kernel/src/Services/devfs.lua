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

        assert(mode == "r", "Unable to open device in write mode: Not allowed")

        local name = string.sub(file, 2, string.len(file))
        local pos = #proxy.handles + 1
        local value = {device=name, file=file}
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
            k.write("36 is true " .. dump(handle))
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
        if path:sub(-5) == ".attr" then return true end
        return proxy.devices[string.sub(path, 2)] ~= nil and proxy.devices[string.sub(path, 2)].api ~= nil
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
    proxy.size = function(filepath)
        checkArg(1, filepath, "string")
        return (proxy.devices[filepath:sub(2)].opts or {}).size or 0
    end
    proxy.read = function(handle, count)
        checkArg(1, handle, "number")
        if proxy.handles[handle].file:sub(-5, -1) == ".attr" then
            proxy.handles[handle].read = (proxy.handles[handle].read or 0) + 1
            if proxy.handles[handle].read == 1 then
                local device = proxy.devices[proxy.handles[handle].device:sub(1, -6)]
                if device == nil then
                    k.write(proxy.handles[handle].device:sub(1, -6)) 
                    return nil, "No device Found!"
                end
                local permissions = device.opts.permissions
                return string.format([[
mode: %s
    
uid:0
created:0
gid:0
                ]], permissions or "r--r--r--")
            else
                return nil -- indicate EOF
            end
        end
        error("Devices doesn't support read: " .. dump(proxy.handles[handle]))
    end
    
    proxy.register = function(name, api, opts)
        checkArg(1, name, "string")
        checkArg(2, api, "table")
        checkArg(3, opts, "table", "nil")
        proxy.devices[name] = {api=api, opts=opts or {}}
    end

    proxy.ioctl = function(handle, method, ...)
        checkArg(1, handle, "number")
        checkArg(2, method, "string")
        

        if not proxy.ensureOpen(handle) then
            k.panic("Handle is not open")
            return {}
        end
        local r = table.pack(proxy.devices[proxy.handles[handle].device].api[method](...))
        return r
    end
    proxy.getAPI = function(handle)
        checkArg(1, handle, "number", "string")
        if type(handle) == "number" then
            if not proxy.ensureOpen(handle) then return nil end
            return proxy.devices[proxy.handles[handle].device].api
        end
        return proxy.devices[handle].api
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