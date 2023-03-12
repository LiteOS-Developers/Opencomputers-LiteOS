local shell = {}
local fs = require("Service").getService("filesystem")
local io = require("System.io")
local users = require("System.Users")

if _G.activeShells == nil then
    _G.activeShells = {}
end

function print(msg, newLine)
    _G.write(msg, newLine)
end
function syscall(name, args)
    local result, err = coroutine.yield("syscall", name, args)
    coroutine.yield()
    -- _G.write("syscall(" .. name .. ") -> " .. dump(result))
    if not result and err then
        err = err .. "\n\n" .. debug.traceback()
        for _, line in pairs(split(err, "\n")) do
            _G.write(line)
        end
    end
    return result[1]
end

shell.getTTY = function(name)
    local d = syscall("getDevice", name)
    if d == nil then
        return nil
    end
    if d.devicetype == "shell" then
        return d.api
    end
    return nil
end


local appEnv = {
    getTTY = shell.getTTY,
    inTable=inTable,
    package=package,
    require=package.require,
    threading=_G.threading,
    math=_G.math,
    debug=_G.debug,
    ["bit32"] = _G["bit32"],
    table=_G.table,
    string=_G.string,
    split=_G.split,
    error=_G.error,
    syscall=syscall,
    computer={
        pushSignal=_G.computer.pushSignal,
        pullSignal=_G.computer.pullSignal,
    },
    os=_G.os,
    toint=_G.rmFloat,
    tostring=_G.tostring,
    tonumber=_G.tonumber,
    type=_G.type,
    ipairs=_G.ipairs,
    pairs=_G.pairs,
    assert=_G.assert,
    getmetatable=_G.getmetatable,
    setmetatable=_G.setmetatable,
    load=_G.load,
    next=_G.next,
    select=_G.select,
    pcall=_G.pcall,
    xpcall=_G.xpcall,
    rawequal=_G.rawequal,
    rawget=_G.rawget,
    rawlen=_G.rawlen,
    checkArg=_G.checkArg,
    dump=_G.dump,
    coroutine = coroutine,
}

local simPrint = function(s)
    -- return s
end

local function inTable(t, k)
    for kt, v in pairs(t) do
        if v == k then
            return true
        end
    end
    return false
end

local function tableCombine(t, com)
    local result = {}
    for k,v in pairs(t) do
        if inTable(com, k) then
            result[k] = v
        end
    end
    return result
end

local function stringJoin(sep, t)
    local r = ""
    for item in t do
        r = r .. sep .. tostring(item)
    end
    return r
end

shell.create = function(pwd, devicename)
    local sh = {
        env={},
        path="",
        name=nil,
    }
    sh.gpu = _G.devices.gpu
    
    local file = syscall("fopen", {"/Config/env", "r"})
    -- _G.write(dump(file))
    local data = ""
    local buf
    repeat
        buf = syscall("fdread", {file, math.huge})
        data = data .. (buf or "")
    until not buf
    syscall("fdclose", file)
    coroutine.yield()

    data = string.gsub(data, "\r", "")
    lines = split(data, "\n")
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
        -- _G.write(key .. " = " .. value)  
        sh.env[key] = value
    end
    
    function sh:setenv(name, value) self.env[name] = value end
    function sh:getenv(env) return self.env[env] end
    function sh:getAllEnvs() return self.env end
    function sh:setAllEnvs(envs)
        self:print(dump(envs))
        self.env = envs
    end

    function sh:getGPU()
        return syscall("getDevice", "gpu")
    end

    function sh:chdir(newpath)
        self.env["PWD"] = newpath
    end
    function sh:getpwd() 
        local pwd = self.env["PWD"] or "/"
        if string.sub(pwd, string.len(pwd)-1, -1) == "/" then
            return string.sub(pwd, 1, -2)
        end
        return pwd
    end
    
    function sh:error(ok, err)
        if ok == false then
            self.gpu.setDepth(8)
            self:setFore(0xF00000)
    
            for k, v in pairs(split(string.gsub(err, "\t", "  "), "\n")) do
                self:print(v)
            end
            self:setFore(0xFFFFFF)
            return false
        end
        return true
    end

    function sh:execute(file, args)
        checkArg(1, file, "string")
        checkArg(2, args, "table", "nil")
        args = args or {}

        local env = appEnv
        env.shell = self
        env._G = _G
        if not fs.isFile(file) then
            return false, "FileNotFound"
        end
        ok, err = xpcall(system.executeFile, debug.traceback, file, env)
        
        if ok == true and err == nil then
            return false, "CommandNotFound"
        elseif self:error(ok, err) then
            local features = {}

            if type(err.features) == "table" then
                local allFeatures = {
                    ["PARENT_SHELL"] = self 
                }
                features = tableCombine(allFeatures, err.features)
            end
            if err.main ~= nil then -- and err.features ~= nil
                -- local args = split(command, " ")

                ok, err = xpcall(err.main, debug.traceback, features, args)
                if self:error(ok, err) then
                    return tonumber(err)
                end
            else
                return false, "NoEntrypoint"
            end
        end
    end

    function sh:auth(maxAttempts, username)
        iUsername = username
        maxAttempts = maxAttempts or math.huge
        local attempts = 0
        while attempts < maxAttempts do

            if username == nil then
                username = self:read("Username> ")
            end
            system.sleep(0.02)

            hostname = io.getFileContent("/Config/hostname")
            password = self:read(username .. "@" .. hostname .. "'s Password> ")
            local result = users.login(username, password)
            system.sleep(0.02)
            if result.result == true then
                return {
                    success=true,
                    username=username,
                    home=result.home,
                    hostname=hostname
                }
            end
            attempts = attempts + 1
            
            if attempts >= maxAttempts then
                self:print("Invalid Password. Reached max attempts")
                break
            else
                self:print("Invalid username or password. Please try again")
            end
            username = nil
    
            ::loopEnd::
        end
        return {success=false}
    end

    function sh:resolvePath(dir) 
        if string.sub(dir, 1, 1) ~= "/" then
            dir = self:getpwd() .. "/" .. dir
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

    
    function sh:print(msg, newLine)
        local lines = split(msg, "\n")
        for i, v in ipairs(lines) do
            if i == #lines then
                print(v, newLine)
            else 
                print(v)
            end
        end
    end
    function sh:setFore(color, isPalette)
        color = color or 0xFFFFFF
        return _G.devices.gpu.setForeground(color, isPalette)
    end
    -- function sh:clear()
    --     local w,h = syscall("getResolution", self.gpu)
        
    --     success = _G.devices.gpu.fill(0, 0, w, h, " ")
    --     if success then
    --         _G.screen.x = 1
    --         _G.screen.y = 1
    --         return true
    --     end
    --     return false
    -- end
    function sh:resolve(name)
        if self.env.PATH == nil then
            return ""
        end
        paths = split(self.env.PATH, ":")
        for k, v in pairs(paths) do
            if fs.isDirectory(v) then
                for _, n in ipairs(fs.listDir(v)) do
                    if n == name .. ".lua" then
                        return v .. "/" .. name .. ".lua"
                    end
                end
            end
        end
        pwd = self.env["PWD"]
        if pwd:sub(1, 1) == "/" then
            pwd = pwd:sub(2, -1)
        end
        if fs.isFile(pwd .. "/" .. name .. ".lua") then
            return pwd .. "/" .. name .. ".lua"
        end

        return nil
    end
    function sh:read(msg)
        local value = ""
        print(msg, false)
        local x = _G.screen.x
        local y = _G.screen.y

        while true do
            key = getKey()
            if key == "BACKSPACE" and _G.screen.x - string.len(msg) >= 1 then
                _G.screen.x = _G.screen.x - 1
                _G.devices.gpu.fill(0, _G.screen.y, _G.screen.w, 1, " ")
                value = string.sub(value, 0, -2)
                _G.screen.x = 1
                print(msg .. value, false)
                _G.screen.x = string.len(msg) + string.len(value) + 1
            elseif key == "BACKSPACE" then goto nothing
            elseif key == "TAB" then
                print("    ", false)
                value = value .. "    "
            elseif key == "ENTER" then
                print("")
                return value
            elseif key == "STRG" then goto nothing
            elseif key == "RSTRG" then goto nothing
            elseif key == "ALT" then goto nothing
            elseif key == "CAPSLOCK" then goto nothing
            elseif key ~= nil then
                value = value .. key
                print(key, false)
            end
            --write(key)
            ::nothing::
            system.sleep(0.1)
        end
    end
    function sh:createDevice(devicename)
        local condition = devicename ~= nil and syscall("getDevice", devicename) == nil
        simPrint("Name: " .. dump(devicename))
        if condition then   
            self.name = tostring(devicename)
            syscall("addDevice", {devicename, {devicetype = "shell", api = self}})
        else
            -- _G.write("Not Created")
        end
    end
    function sh:mapToTTY()
        -- _G.write("mapToTTY: " .. dump(self.name))
        if type(self.name) ~= "string" then return type(self.name) end
        local old = shell.getTTY("tty")
        -- _G.write(self.name)
        syscall("mapDevice", {self.name, "tty"})
        return old
    end
    
    return sh
end



return shell