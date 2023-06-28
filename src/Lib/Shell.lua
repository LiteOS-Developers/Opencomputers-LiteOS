local api = {}
local fs = filesystem


api.syscall = syscall
api.ioctl = ioctl


api.connect = function(tty)
    checkArg(1, tty, "string")

    local device, e = filesystem.open("/dev/" .. tty, "r")
    if device == nil then
        error(e)
    end
    if not filesystem.ensureOpen(device) then
        error("Cannot open device: " .. dump(fs.listDir("/dev"))) 
    end

    local sh = {}

    function sh:getInfo()
        return api.ioctl(device, "getInfo")
    end
    function sh:chdir(dir)
        checkArg(1, dir, "string", "nil")
        return api.ioctl(device, "chdir", dir)
    end
    function sh:getenv(key)
        checkArg(1, key, "string", "nil")
        return api.ioctl(device, "getenv", key)
    end
    function sh:setenv(key, value)
        api.ioctl(device, "setenv", key, value)
    end
    function sh:execute(file, ...)
        checkArg(1, file, "string")
        local result, err = api.ioctl(device, "execute", file, ...)
        if not result then return -1, err end
        repeat
            coroutine.yield()
        until result.stopped
        return result.result, err
    end
    function sh:auth(username)
        checkArg(1, username, "string", "nil")
        return api.ioctl(device, "auth", username)
    end

    function sh:resolve(name)
        checkArg(1, name, "string")
        local path = self:getenv("PATH")
        if path == nil then
            return nil, "PATH variable isn't set"
        end
        paths = split(path, ":")
        for key, v in pairs(paths) do
            if filesystem.isDirectory(v) then
                for _, n in ipairs(filesystem.listDir(v)) do
                    if n == name .. ".lua" then
                        return v .. "/" .. name .. ".lua"
                    end
                end
            end
        end
        pwd = self:chdir()
        if pwd:sub(1, 1) == "/" then
            pwd = pwd:sub(2, -1)
        end
        if fs.isFile(pwd .. "/" .. name .. ".lua") then
            return pwd .. "/" .. name .. ".lua"
        end

        return nil
    end

    function sh:print(line)        
        if not filesystem.ensureOpen(device) then
            _G.print("Device Not Opened!")
            return false
        end

        local resp, err = api.ioctl(device, "print", tostring(line))
    end
    function sh:cursor(x, y, fg, bg)
        checkArg(1, x, "number")
        checkArg(2, y, "number")
        checkArg(3, fg, "number")
        checkArg(3, bg, "number")
        local cursor = {
            x = x,
            y = y,
        }
        cursor.id = api.ioctl(device, "createCursor", x, y, {fg = fg, bg = bg})
        function cursor:moveTo(x, y)
            local v = table.pack(api.ioctl(device, "cursorMove", self.id, x, y))
            cursor.x = x
            cursor.y = y
            return table.unpack(v)
        end
        return cursor
    end

    function sh:read(msg)
        checkArg(1, msg, "string")
        return api.ioctl(device, "read", msg)
    end

    function sh:resolvePath(dir)
        if string.sub(dir, 1, 1) ~= "/" then
            dir = self:chdir() .. "/" .. dir
        end
        local d = ""
        for k, v in pairs(split(dir, "/")) do
            if v == ".." and d ~= "/" then
                local parts = split(d, "/")
                table.remove(parts, #parts)
                d = ""
                for _, p in pairs(parts) do
                    d = d .. "/" .. p
                end
            elseif v == "." then
            else
                d = d .. "/" .. v
            end
        end
        return d
    end
    function sh:close()
        return table.unpack(fs.close(device))
    end

    function sh:alias()
        return table.unpack(api.ioctl(device, "setDefault"))
    end
    return sh
end

api.create = function(pwd)
    checkArg(1, pwd, "string", "nil")
    pwd = pwd or "/"
    local device = fs.open("/dev/tty0", "r")
    local res = api.ioctl(device, "createSubshell", pwd)
    fs.close(device)
    return res
end

return api