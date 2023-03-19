k.printk(k.L_INFO, "Initializing shell")
local event = require("Event")
if not event then
    k.panic("Unable to load Event Library")
end
local sandbox = require("Sandbox")
if not sandbox then
    k.panic("Unable to load Sandbox Library")
end

k.shell = {}
k.shell.current = "tty0"
k.shell.all = {}


k.shell.parseEnv = function(filename)
    checkArg(1, filename, "string")
    local file = k.filesystem.open(filename, "r")
    local data = ""
    local buf
    repeat
        buf = k.filesystem.read(file, math.huge)
        data = data .. (buf or "")
    until not buf
    k.filesystem.close(file)

    data = string.gsub(data, "\r", "")
    lines = split(data, "\n")
    local env = {}
    for i, line in ipairs(lines) do
        local key = ""
        local value = ""
        for i, item in pairs(split(line, "=")) do
            if i == 1 then
                key = item
            else
                value = value .. item
            end
        end
        env[key] = value
    end
    return env
end

k.shell.create = function(pwd, env, name)
    checkArg(1, pwd, "string")
    checkArg(2, env, "table")
    checkArg(3, name, "string", "nil")

    local sh = {
        pwd = "/",
        env={},
    }
    function sh.device()
        return k.devices.register("tty0", sh)
    end

    function sh.chdir(dir)
        checkArg(1, dir, "string", "nil")
        if dir == nil then
            return sh.pwd
        end
        sh.pwd = dir
    end

    function sh.getenv(key)
        checkArg(1, key, "string", "nil")
        if key == nil then
            return sh.env
        end
        return sh.env[key]
    end

    function sh.setenv(key, value)
        checkArg(1, key, "string")
        checkArg(2, value, "string")
        sh.env[key] = value
    end

    function sh.execute(file, args)
        checkArg(1, file, "string")
        checkArg(2, args, "table", "nil")
        
        if k.filesystem.isFile(file) then
            args = args or {}
            local env = sandbox.create_env()
            local _ENV = _G
            _G = env
            if _G.k ~= nil then
                _ENV.k.panic("Kernel global is not cleared!")
            end
            local thread = _ENV.k.threading.createThread(file, function()
                local f = _ENV.k.system.executeFile(file, env)
                return f.main(args)
            end)
            
            thread:start()
            _G = _ENV
            return thread, nil
            
        end
        return nil, "No File"
    end

    function sh.auth(username)
        checkArg(1, username, "string", "nil")
        local username, password

        while true do
            local data = table.pack(event.pull("key_down"))
            local char = utf8.char(data[2])
            sh.print(char)
        end
    end

    function sh.print(line, e)
        checkArg(1, line, "string")
        checkArg(2, e, "string", "nil")
        e = e or "\n"
        local x, y = k.screen.x, k.screen.y
        k.write(line)
        if e ~= "\n" then
            k.screen.x = x + string.len(e)
            k.screen.y = y
            k.write(e)
        end
        return true
    end

    function sh.read(msg)
        checkArg(1, msg, "string", "nil")
        msg = msg or ""
        --local data = table.pack(event.pull("key_down"))
        --local char = utf8.char(data[2])
        --sh.print(char)
    end

    function sh.createSubshell(pwd)
        checkArg(1, pwd, "string")
        return k.shell.create(pwd, sh.env)
    end

    function sh.setDefault()
        k.devices.mapDevice("tty", sh.name)
    end

    local id = #k.shell.all
    sh.name = name or "tty" .. tostring(id)
    repeat
        id = id + 1
        sh.name = name or "tty" ..tostring(id)
    until k.devices.devices[sh.name] == nil

    table.insert(k.shell.all, sh)

    return sh
end

k.shell.default = k.shell.create("/", k.shell.parseEnv("/Config/env"), "tty0")
k.shell.default:device()
k.shell.default:setDefault()