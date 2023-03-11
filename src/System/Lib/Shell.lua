local shell = {}
local fs = require("Service").getService("filesystem")
local io = require("System.io")
local users = require("System.Users")
function print(msg, newLine)
    _G.write(msg, newLine)
end
function syscall(name, ...)
    _G.write(dump(coroutine.yield))
    local result = coroutine.yield("syscall", name, ...)
    _G.write("syscall(" .. name .. ") -> " .. dump(result))
    return result
end

shell.getTTY = function(name)
    local d = syscall("getDevice", name)
    _G.write("READ DEVICES LIST: " .. dump(d))
    if d == nil then
        _G.write("D IS NIL x1")
        return nil
    end
    if d[1] == nil then
        _G.write("D IS NIL x2")
        return
    end
    d = d[1]
    if d.devicetype == "shell" then
        _G.write("FOUND EXISITING SHELL")
        return d.api
    end
    _G.write("D IS NIL x3: " .. dump(d["devicetype"]))

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

shell.create = function(pwd, devicename)
    local sh = {
        env={},
        path="",
    }
    sh.gpu = _G.devices.gpu

    function sh:chdir(newpath)
        self.env["PWD"] = newpath
    end
    function sh:setenv(name, value)
        self.env[name] = value
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
            -- shell:print()
            self:setFore(0xFFFFFF)
            return false
        end
        return true
    end

    function sh:execute(file, args)

        checkArg(1, file, "string")
        checkArg(2, args, "table", "nil")

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
            if err.main ~= nil and err.features ~= nil then
                local allowedFeatures = err.features
                -- local args = split(command, " ")

                ok, err = xpcall(err.main, debug.traceback, allowedFeatures, args)
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
            end
    
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

    function sh:getenv(env) return self.env[env] end
    
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
    function sh:clear()
        local w,h = syscall("getResolution", self.gpu)
        
        success = _G.devices.gpu.fill(0, 0, w, h, " ")
        if success then
            _G.screen.x = 1
            _G.screen.y = 1
            return true
        end
        return false
    end
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
        -- _G.write(dump(devicename ~= nil and syscall("getDevice", devicename) == nil))
        simPrint("Name: " .. dump(syscall("getDevice", devicename)))
        local condition = devicename ~= nil and syscall("getDevice", devicename) == nil
        if condition then
            _G.write("STORE")
            syscall("addDevice", {devicename, {devicetype = "shell", api = sh}})
            if syscall("getDevice", devicename) == nil then
                _G.write("[E] Device creation Failed")
            end
            return
        else
            _G.write("RESULT OF createDevice " .. dump(devicename) .. " " .. dump(condition))

        end
    end
    -- 
    -- local x = {syscall, devicename}
    -- _G.write(dump(syscall("getDevice", devicename) == nil))
    
    return sh
end



return shell