-- k.printk(k.L_INFO, "Initializing shell")
k.printk(k.L_INFO, " - 13_shell")

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
    local lines = split(data, "\n")
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
        env=env,
    }
    sh.env.pwd = pwd
    function sh.device()
        return k.devices.register("tty0", sh)
    end

    function sh.chdir(dir)
        checkArg(1, dir, "string", "nil")
        if dir == nil then
            return sh.env.pwd
        end
        sh.env.pwd = dir 
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
        -- checkArg(2, value, "string")
        sh.env[key] = tostring(value)
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
        local password
        local hostname = k.io.getFileContent("/Config/hostname")

        while true do
            if username == nil then
                username = sh.read("Username> ")
            end
            password = sh.read(username .. "@" .. hostname .. "'s password> ", "*")
            local result = k.users.login(username, password)
            -- k.write(dump(result))
            if result.result then
                return {
                    success = true,
                    home = result.home,
                    hostname = hostname,
                    username = username
                }
            else 
                sh.print("Invalid username or password. Please try again")
                username = nil
                password = nil
            end
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

    function sh.read(msg, replacement)
        checkArg(1, msg, "string", "nil")
        checkArg(2, replacement, "string", "nil")
        if replacement ~= nil then replacement = replacement:sub(1, 1) end
        msg = msg or ""
        local result = ""
        local w, h = k.gpu.getResolution()
        k.gpu.set(1, k.screen.y, msg)
        k.screen.x = k.screen.x + msg:len() - 1
        local x = k.screen.x - 1
        local y = k.screen.y
        k.gpu.setForeground(0xFFFFFF)
        k.gpu.setBackground(0x000000)
        while true do
            local _, addr, char, code, player = table.unpack(event.pull("key_down"))
            local utfChar = utf8.char(char)
            char = tonumber(tostring(string.format("%.0f", char)))
            if utfChar == "\b" then
                local oldLen = result:len()
                result = result:sub(1, result:len() - 1)
                k.gpu.fill(k.screen.x, k.screen.y, x, y, " ")
                if not replacement then
                    k.gpu.set(x + 2, y, result)
                else
                    k.gpu.set(x + 2, y, replacement:rep(result:len()))
                end
                k.screen.x = x + result:len() + 1
            elseif utfChar == "\r" then
                k.screen.x = 1
                k.screen.y = k.screen.y + 1
                if k.screen.y > h then
                    k.gpu.copy(1, 2, w, h - 1, 0, -1)
                    k.gpu.fill(1, h, w, 1, " ")
                    k.screen.y = k.screen.y - 1
                end
                return result
            elseif utfChar == "\t" then
                result = result .. "    "
                k.gpu.set(k.screen.x, k.screen.y, "    ")
                k.screen.x = k.screen.x + 4
            else
                if char == 0 or char == 8 or char == 9 or char == 13 then
                else
                    result = result .. utfChar
                    k.screen.x = k.screen.x + 1
                    k.gpu.set(k.screen.x, k.screen.y, replacement or utfChar)
                end
            end
        end
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