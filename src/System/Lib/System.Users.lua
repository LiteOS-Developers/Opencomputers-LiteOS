local api = {currentUser=nil}
local fs = require("Service").getService("filesystem")
local io = require("System.io")

api.setCurrentUser = function(val)
    api.currentUser = val
end

function tohex(str)
    return (str:gsub('.', function (c)
        return string.lower(string.format('%02X', string.byte(c)))
    end))
end

api.login = function(user, password)
    local ctn = io.getFileContent("/Config/users")
    ctn = split(ctn, "\n")
    for k, v in pairs(ctn) do
        if string.sub(v, -1) == "\r" then
            v = string.sub(v, 0, -2)
        end
        
        local splitted = split(v, ":")

        username, hash, home = table.unpack(splitted)
        local hash2 = tohex(_G.devices.data.sha256(password))
        local result = hash2 == hash and username == user
        ret = {result=result}
        if result then
            ret.home = home
        end
        return ret
    end
    return false
end

return api