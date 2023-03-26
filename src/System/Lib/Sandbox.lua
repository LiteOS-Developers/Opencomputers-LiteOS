local api = {}



local builtins = {}

builtins.syscall = function(call, ...)
    -- k.write("before")
    local result = table.pack(coroutine.yield("syscall", call, ...))
    -- k.write("after")
    
    if result[1] ~= "syscall" then
        k.write(dump({call, ...}))
    end
    table.remove(result, 1)
    coroutine.yield()
    return table.unpack(result)
end

builtins.ioctl = function(handle, func, ...)
    local v = builtins.syscall("ioctl", handle, func, ...)
    if type(v) ~= "table" then
        return v
    end
    -- k.write(func .. " " .. dump(v))
    return table.unpack(v)
end

local function copyBlacklist(t, list)
    local new = deepcopy(t)
    for key in pairs(list) do new[key] = nil end
    return new
end


local blacklist = {
    component = true, computer = true, k = true, sName=true, package = true, s = true, require = true, rmFloat = true, VERSION_INFO = true,
    scall = true, services = true, tohex = true, getValueFromKey = true, mounts = true, getFirst = true, filesystem = true, inTable = true,
    lib = true
}

api.create_env = function(base)
    checkArg(1, base, "table", "nil")

    local new = deepcopy(base or _G)
    for key, v in pairs(blacklist) do new[key] = nil end
    
    new.load = function(a, b, c, d)
        return k.load(a, b, c, d or new) -- k.current_process().env
    end
    new.error = function(l)
        local info = debug.getinfo(3)
        t = info.short_src .. ":" .. tostring(info.currentline) .. ": " .. l .. "\n" .. debug.traceback()
        new.io.stderr:writelines(t)
        local thread = new.threading.getCurrent()
        thread:stop()
        coroutine.yield()
    end
    new.print = function(...)
        new.io.stdout:writelines(...)
    end

    -- if includePackage then
    new.dofile = function(path)
        local res, e = dofile(path, new)
        if not res then
            return nil, e
        end
        return res
    end
    new.package = new.dofile("/Lib/Package.lua")
    new.require = new.package.require
    -- end

    new.computer = {
        uptime = computer.uptime,
        freeMemory = computer.freeMemory,
        totalMemory = computer.totalMemory,
        -- freeMemory = computer.freeMemory,
    }
    new.event = deepcopy(k.event)
    new.threading = k.threading
    local filesystem = k.filesystem
    
    new.filesystem = {
        open = filesystem.open,
        read = filesystem.read,
        write = filesystem.write,
        seek = filesystem.seek,
        close = filesystem.close,
        listDir = filesystem.listDir,
        getFilesize = filesystem.getFilesize,
        getLastEdit = filesystem.getLastEdit,
        ensureOpen = filesystem.ensureOpen,
        isFile = filesystem.isFile,
        isDirectory = filesystem.isDirectory
    }

    new.scall = k.scall


    -- new.coroutine.yield = coroutine.yield
    
    --[[new.syscall = function(call, ...)
        local result, err = new.coroutine.yield("syscall", call, ...)
        new.print(dump(result))
        new.print(dump(err))
        return result
    end
    new.ioctl = function(handle, func, ...)
        return new.syscall("ioctl", handle, func, ...)
    end]]
    new.syscall = builtins.syscall
    new.ioctl = builtins.ioctl

    --[[ if new.coroutine.resume == coroutine.resume then
        local resume = new.coroutine.resume

        function new.coroutine.resume(co, ...)
            local result
            repeat
                result = table.pack(resume(co, ...))
                if result[2] == k.sysyield_string then
                    yield(k.sysyield_string)
                end
            until result[2] ~= k.sysyield_string or not result[1]

            return table.unpack(result, 1, result.n)
        end
    end]]
    
    return new
end

return api
