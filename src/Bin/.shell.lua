local api = {}
local shell = require("Shell")
-- error(dump(shell))

local function parseArgs(args)
    local i = 1
    local res = {}
    if #args == 0 then return {} end
    repeat
        if type(args[i]) ~= "string" then error("Invalid type of Argument") end
        if args[i]:sub(1, 2) == "--" then
            if i < #args and args[i+1]:sub(1,1) ~= "-" then
                res[args[i]:sub(3,string.len(args[i]))] = args[i+1]
            else
                res[args[i]:sub(3,string.len(args[i]))] = true
            end
        end
        i = i + 1
    until i == #args
    return res
end

api.features = {
    "PARENT_SHELL"
}
api.main = function(granted, args)

    args = parseArgs(args or {})
    local sh, oldDefault
    if type(args.shell) == "string" and args.shell:sub(1, 3) == "tty" then
        sh = shell.getTTY(args.shell)
        sh:setenv("SHELLID", args.shell)
        sh:setenv("SHELL", "/Bin/shell.lua")
    else
        sh = shell.create("/")

        local devices = syscall("filterDevices", "tty")[1]
        local id = #devices
        if inTable(devices, "tty") then
            id = id - 1
        end
        local name = "tty" .. tostring(id)
        while inTable(devices, name) do
            id = id + 1
            name = "tty" .. tostring(id)
            coroutine.yield()
        end
        sh:createDevice(name)
        oldDefault = sh:mapToTTY()
        sh:setenv("SHELL", "/Bin/shell.lua")
        sh:setenv("SHELLID", name)
    end
    
    parent = granted["PARENT_SHELL"]
    -- sh:print(dump(granted))
    local result = sh:auth(nil, args["user"])
    sh:print("Logged In")
    sh:chdir(result.home)
    if parent ~= nil then
        sh.env = parent.env
        for k, v in pairs(parent:getAllEnvs()) do
            if k == "PATH" and sh:getenv("PATH") == nil then
                sh:setenv("PATH", sh:getenv("PATH") .. ":" .. v)
            else
                sh:setenv(k, v)
            end
        end
    else
        sh:setenv("PATH", "/Bin:/Users/Bin")
    end
    local command, cmd, pwd, path, arguments, exitCode
    local host = result.username .. "@" .. result.hostname
    while true do
        pwd = sh:getpwd()
        if string.len(pwd) == 0 then pwd = "/" end
        command = sh:read(host .. ":" .. pwd .. "# ")
        if command == "exit" then
            break
        end
        arguments = split(command, " ")
        cmd = arguments[1]
        table.remove(arguments, 1)
        if cmd == nil then goto shellContinue end
        path = sh:resolve(cmd)
        if path == nil or not syscall("isFile", path) then
            sh:print(cmd .. ": Command not found")
            goto shellContinue
        end

        args = split(command, " ")
        exitCode = sh:execute(path, arguments) or 0
        sh:setenv("EXIT", tonumber(exitCode))
        ::shellContinue::
    end
    if oldDefault ~= nil then
        oldDefault:mapToTTY()
    end
    return 0
end

return api
