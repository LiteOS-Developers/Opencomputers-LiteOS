local api = {}

function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy, t
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            t = deepcopy(getmetatable(orig), copies)
            if type(t) == "table" or type(t) == "nil" then
                setmetatable(copy, t)
            end
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local builtins = {}

builtins.syscall = function(call, ...)
    local result = table.pack(coroutine.yield("syscall", call, ...))
    
    if result[1] ~= "syscall" then
        k.write(err)
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
    component = true, computer = true, k = true, sName=true
}

api.create_env = function(base)
    checkArg(1, base, "table", "nil")

    local new = copyBlacklist(base or _G, blacklist)
    
    new.load = function(a, b, c, d)
        return k.load(a, b, c, d or {}) -- k.current_process().env
    end
    new.error = k.panic
    new.package = require("Package")
    new.require = new.package.require

    new.computer = {
        uptime = computer.uptime
    }
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

    new.print = k.write

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
