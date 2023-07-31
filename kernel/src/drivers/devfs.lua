--#ifndef UUID
--#error UUID is not loaded
--#endif
--#define DRV_DEVFS
k.printk(k.L_INFO, "drivers/devfs")
k.devfs = {}

k.devfs.create = function()
    local proxy = {}
    proxy.addr = k.uuid.next()
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
        local value = {device=name, file=file}
        proxy.handles[pos] = value
        if proxy.handles[pos] == nil then
            k.println(dump(proxy.handles[pos] == nil))
            k.panic("Device " .. tostring(pos) .. " not opened correctly")
        end
        return pos
    end
    proxy.ensureOpen = function(handle)
        checkArg(1, handle, "number")
        if type(proxy.handles[handle]) ~= "table" then
            k.println("36 is true " .. dump(handle))
            return false
        end 
        return proxy.handles[handle].closed ~= true
    end
    proxy.seek = function(handle, wh, off)
        checkArg(1, handle, "number")
        checkArg(2, count, "number")
        local device = proxy.handles[handle].device
        device = proxy.device[device]
        if device.api.seek then
            return device.api.seek(wh, off)
        end
        error("That device doesn't support seek: " .. proxy.handles[handle].device)
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
        checkArg(1, handle, "number")
        checkArg(2, buf, "string")
        local device = proxy.handles[handle].device
        device = proxy.device[device]
        if device.api.write then
            return device.api.write(buf)
        end
        error("That device doesn't support write: " .. proxy.handles[handle].device)
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
    proxy.getAttrs = function(file)
        local file = file:sub(2)
        local device = proxy.devices[file]
        if device == nil then
            k.println(proxy.handles[handle].device:sub(1, -6)) 
            return nil, "No device Found!"
        end
        return {
            mode = device.opts.permissions,
            uid = 0,
            gid = 0,
            created = 0
        }
    end
    proxy.read = function(handle, count)
        checkArg(1, handle, "number")
        checkArg(2, count, "number")
        local device = proxy.handles[handle].device
        device = proxy.device[device]
        if device.api.read then
            return device.api.read(count)
        end
        error("That device doesn't support read: " .. proxy.handles[handle].device)
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