local shell = require("Shell")
local fs = filesystem

_G.print = print

return {
    main = function(args)
        local sh = shell.connect("tty")
        sh:setenv("SHELL", "/Bin/shell.lua")
        local res = sh:auth()
        if not res.success then
            sh:print("Not Logged In.")
            return -1
        end
        sh:print("Logged In")
        sh:chdir(res.home)
        
        local host = res.username .. "@" .. res.hostname
        local pwd, path, e
        while true do
            pwd = sh:chdir()
            if string.len(pwd) == 0 then pwd = "/" end
            command = sh:read(host .. ":" .. pwd .. "# ")
            if command:len() == 0 then goto continue end
            -- print(dump(command))
            if command == "exit" then
                break
            end
            local arguments = split(command, " ")
            local cmd = arguments[1]
            local args = select(2, arguments)
            if cmd == nil then
                sh:print(command .. ": Command not found")
                goto continue
            end
            path, e = sh:resolve(cmd)
            if path == nil or not fs.isFile(path) then
                sh:print(cmd .. ": Command not found: " .. dump(e))
                goto continue
            end
            exitCode = sh:execute(path, arguments) or 0
            
            sh:setenv("EXIT", tonumber(exitCode))     
            ::continue::
        end
        return 0
    end
}