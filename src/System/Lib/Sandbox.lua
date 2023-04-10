local api = {}
local builtins = {}

builtins.syscall = function(call, ...)
    -- k.write("before")
    -- coroutine.yield()
    local result = table.pack(coroutine.yield("syscall", call, ...))
    coroutine.yield()

    -- k.write("after")
    
    if result[1] ~= "syscall" then
        k.write(dump({call, ...}) .. dump(result))
    end
    table.remove(result, 1)
    return table.unpack(result)
end

builtins.ioctl = function(handle, func, ...)
    local v = builtins.syscall("ioctl", handle, func, ...)
    -- print(dump(v))
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

api.create_env = function(opts)
    checkArg(1, opts, "table", "nil")
    opts = opts or {}
    opts.base = opts.base or _G

    local new = deepcopy(base or _G)
    for key, v in pairs(blacklist) do new[key] = nil end
    local perm_check = false
    local user
    if opts.perm_check ~= true then
        local shell = k.devices.getAPI("tty0")
        user = shell.user or {}
        if user.success then
            perm_check = true
        end
    end
    
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

    new.time = k.time

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

    local function modeTable(m)
        checkArg(1, m, "string")
        local mode = {}
        for i = 1, unicode.len(m) do
            mode[unicode.sub(m, i, i)] = true
        end
        return mode
    end

    local function checkAttrMode(mode)
        checkArg(1, mode, "string")
        assert(mode:len() >= 9, "Expected 'mode' of length 9 got " .. tostring(mode:len()))
        local result = {}
        if mode:sub(1, 1) == "r" or mode:sub(7, 7) == "r" then result.r = true end
        if mode:sub(2, 2) == "w" or mode:sub(8, 8) == "w" then result.w = true end
        if mode:sub(3, 3) == "x" or mode:sub(9, 9) == "x" then result.x = true end
        return result
    end
    -- TODO: check if user is allowed through group 
    
    new.filesystem = {
        open = function(path, m)
            checkArg(1, path, "string")
            checkArg(2, mode, "string", "nil")
            local attrs = filesystem.getAttrs(path)
            m = m or "r"
            local mode = modeTable(m)
            if perm_check then
                if not checkAttrMode(attrs.mode).w and (mode.w or mode.a) then
                    return nil, path .. ": Unable to open for write File: Not allowed"
                end
                if not checkAttrMode(attrs.mode).r and mode.r then
                    return nil, path .. ": Unable to open for read File: Not allowed"
                end
            end
            return filesystem.open(path, m)
        end,
        read = filesystem.read,
        write = filesystem.write,
        seek = filesystem.seek,
        close = filesystem.close,
        listDir = function(dir)
            checkArg(1, dir, "string")
            if dir:sub(-1, -1) == "/" and dir:len() >= 2 then dir = dir:sub(1, -2) end
            local attrs = filesystem.getAttrs(dir)
            -- k.write(dir .. " " .. dump(attrs))
            if attrs.mode ~= nil and not checkAttrMode(attrs.mode).r then
                return nil, "Unable to list directory: Not allowed"
            end
            return filesystem.listDir(dir)
        end,
        getFilesize = filesystem.getFilesize,
        getLastEdit = filesystem.getLastEdit,
        ensureOpen = filesystem.ensureOpen,
        isFile = filesystem.isFile,
        isDirectory = filesystem.isDirectory,
        remove = filesystem.remove,
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
