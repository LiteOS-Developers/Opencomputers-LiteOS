local api = {}
local fs = filesystem


api.syscall = syscall
api.ioctl = ioctl


api.connect = function(tty)
    checkArg(1, tty, "string")

    local device = filesystem.open("/dev/" .. tty, "r")
    if not filesystem.ensureOpen(device) then
        error("Cannot open device: " .. dump(fs.listDir("/dev"))) 
    end

    local sh = {}
    function sh:chdir(dir)
        checkArg(1, dir, "string", "nil")
        return table.unpack(api.ioctl(device, "chdir", dir))
    end
    function sh:getenv(key)
        checkArg(1, key, "string", "nil")
        return table.unpack(api.ioctl(device, "getenv", key))
    end
    function sh:setenv(key, value)
        return table.unpack(api.ioctl(device, "setenv", key, value))
    end
    function sh:execute(file, ...)
        checkArg(1, file, "string")
        local result = api.ioctl(device, "execute", file, ...)
        -- if type(result) == "table" then
        --     return table.unpack(result)
        -- end
        return result
    end
    function sh:auth(username)
        checkArg(1, username, "string", "nil")
        return table.unpack(api.ioctl(device, "auth", username))
    end

    function sh:resolve(name)
        checkArg(1, name, "string")
        local path = self:getenv("PATH")
        if self.env.PATH == nil then
            return ""
        end
        paths = split(path, ":")
        for k, v in pairs(paths) do
            if fs.isDirectory(v) then
                for _, n in ipairs(fs.listDir(v)) do
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

    function sh:print(line)        if not filesystem.ensureOpen(device) then
            _G.print("Device Not Opened!")
            return false
        end

        resp, err = api.ioctl(device, "print", tostring(line))
    end

    function sh:read(msg)
        checkArg(1, msg, "string")
        
        return api.ioctl(device, "read", msg)
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