local api = {}
local builtins = {}

builtins.syscall = function(call, ...)
    local result = table.pack(coroutine.yield("syscall", call, ...))
    coroutine.yield()

    if result[1] ~= "syscall" then
        k.write(dump({call, ...}) .. dump(result))
    end
    table.remove(result, 1)
    return table.unpack(result)
end

builtins.ioctl = function(handle, func, ...)
    local v = builtins.syscall("ioctl", handle, func, ...)
    if type(v) ~= "table" then
        return v
    end
    return table.unpack(v)
end

local function copyBlacklist(t, list)
    local new = deepcopy(t)
    for key in pairs(list) do new[key] = nil end
    return new
end


local blacklist = {
    component = true, computer = true, k = true, sName=true, package = true, s = true, require = true, VERSION_INFO = true,
    scall = true, services = true, tohex = true, mounts = true, filesystem = true, lib = true
}

api.create_env = function(opts)
    checkArg(1, opts, "table", "nil")
    opts = opts or {}
    opts.base = opts.base or _G

    local new = deepcopy(base or _G)
    for key, v in pairs(blacklist) do new[key] = nil end
    local perm_check = false
    local user, shell
    if opts.perm_check ~= true then
        shell = k.devices.getAPI("tty0")
        user = shell.user or {}
        if user.success then
            perm_check = true
        end
    end
    local loadfile = load
    new.load = function(a, b, c, d)
        return loadfile(a, b, c, d or new) -- k.current_process().env
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

    new.dofile = function(path)
        local res, e = dofile(path, new)
        if not res then
            return nil, e
        end
        return res
    end
    new.package = new.dofile("/Lib/Package.lua")
    new.require = function(p)
        local groups = (user or {}).groups or {}
        if p:sub(1,7):lower() == "system." and table.contains(groups, "0") then
            return k.package.require(p:sub(8))
        end
        return new.package.require(p) 
    end
    -- end

    new.computer = {
        uptime = computer.uptime,
        freeMemory = computer.freeMemory,
        totalMemory = computer.totalMemory,
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

    function new.checkAttrMode(attrs, useGroup)
        checkArg(1, attrs, "table")
        mode = attrs.mode
        assert(type(mode) == "string", "Bad Argument #1: table is Empty")
        assert(mode:len() >= 9, "Expected 'mode' of length 9 got " .. tostring(mode:len()))
        local result = {}
        if ((not user.uid or tonumber(attrs.uid) == user.uid) and mode:sub(1, 1) == "r") or mode:sub(7, 7) == "r" then result.r = true end
        if ((not user.uid or tonumber(attrs.uid) == user.uid) and mode:sub(2, 2) == "w") or mode:sub(8, 8) == "w" then result.w = true end
        if ((not user.uid or tonumber(attrs.uid) == user.uid) and mode:sub(3, 3) == "x") or mode:sub(9, 9) == "x" then result.x = true end
        if gid ~= nil and user.groups ~= nil then
            new.print(dump(user))
            if user.groups[gid] ~= nil then
                if mode:sub(4, 4) == "r" then result.r = true end
                if mode:sub(5, 5) == "w" then result.w = true end
                if mode:sub(6, 6) == "x" then result.x = true end
            end
        end
        return result
    end

    new.filesystem = {
        open = function(path, m)
            checkArg(1, path, "string")
            if path:sub(-5, -1) == ".attr" then
                return nil, "File Not Allowed"
            end
            checkArg(2, mode, "string", "nil")
            local attrs = filesystem.getAttrs(path)
            m = m or "r"
            local mode = modeTable(m)
            if perm_check then
                if not new.checkAttrMode(attrs, tonumber(attrs.gid)).w and (mode.w or mode.a) then
                    return nil, path .. ": Unable to open for write File: Not allowed"
                end
                if not new.checkAttrMode(attrs, tonumber(attrs.gid)).r and mode.r then
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
            if attrs.mode ~= nil and not new.checkAttrMode(attrs, tonumber(attrs.gid)).r then
                return nil, "Unable to list directory: Not allowed"
            end
            return filesystem.listDir(dir)
        end,
        getFilesize = filesystem.getFilesize,
        getLastEdit = filesystem.getLastEdit,
        ensureOpen = filesystem.ensureOpen,
        isFile = filesystem.isFile,
        isDirectory = filesystem.isDirectory,
        remove = function(dir)
            checkArg(1, dir, "string")
            if dir:sub(-1, -1) == "/" and dir:len() >= 2 then dir = dir:sub(1, -2) end
            local attrs = filesystem.getAttrs(dir)
            if attrs.mode ~= nil and not new.checkAttrMode(attrs, tonumber(attrs.gid)).w then
                return nil, "Unable to remove file or directory: Not allowed"
            end
            return filesystem.remove(dir)
        end,
        getAttrs = function(f)
            checkArg(1, f, "string")
            if f:sub(-5) == ".attr" then return {}, "File Not Exists" end
            return filesystem.getAttrs(f)
        end
    }

    new.scall = k.scall
    new.syscall = builtins.syscall
    new.ioctl = builtins.ioctl
    
    return new
end

return api
