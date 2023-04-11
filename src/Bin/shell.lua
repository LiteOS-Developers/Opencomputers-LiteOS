local shell = require("Shell")
local fs = filesystem

_G.print = print

return {
    main = function(args)
        local sh = shell.connect("tty0")
        sh:setenv("SHELL", "/Bin/shell.lua")
        local res = sh:auth()
        if not res.success then
            sh:print("Not Logged In.")
            return -1
        end
        sh:print("Logged In")
        sh:chdir(res.home)
        
        local pwd, path, e
        while true do
            res = sh:getInfo()
            local host = res.username .. "@" .. res.hostname
            -- coroutine.yield()
            pwd = sh:chdir()
            if string.len(pwd) == 0 then pwd = "/" end
            command = sh:read(host .. ":" .. pwd .. "# ")
            if command:len() == 0 then goto continue end
            
            local arguments = split(command, " ")
            local cmd = arguments[1]
            if cmd == nil then
                sh:print(command .. ": Command not found")
                goto continue
            end
            path, e = sh:resolve(cmd)
            if path == nil or not fs.isFile(path) then
                sh:print(cmd .. ": Command not found: " .. dump(e))
                goto continue
            end
            exitCode, e = sh:execute(path, arguments)
            if e ~= nil then
                print(path .. ": " .. tostring(e))
            end
            -- coroutine.yield()
            -- coroutine.yield()
            -- coroutine.yield()
            if type(exitCode) == "number" then
                sh:setenv("EXIT", tostring(tonumber(exitCode)))
            else
                sh:setenv("EXIT", tostring(0))
            end
            ::continue::
        end
        return 0
    end
}