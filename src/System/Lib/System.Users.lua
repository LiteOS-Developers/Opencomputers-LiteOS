local api = {}
local fs = require("Service").getService("filesystem")
local io = require("System.io")



function tohex(str)
    return (str:gsub('.', function (c)
        return string.lower(string.format('%02X', string.byte(c)))
    end))
end

api.readGroups = function()
    local ctn = io.getFileContent("/Config/groups")
    ctn = split(ctn, "\n")
    local result = {}
    for _, v in pairs(ctn) do
        if string.sub(v, -1) == "\r" then
            v = string.sub(v, 0, -2)
        end
        local gid, name = table.unpack(split(v, ":"))
        gid = tonumber(gid)
        if result[gid] ~= nil then
            error("Cannot Load Groups: Multiple entries with same gid")
        end
        if gid == nil then
            error(gid .. " " .. name)
        end
        result[gid] = name
    end
    return result
end

local function filterTable(t, keys)
    local result = {}
    for i, k in ipairs(keys) do
        if t[k] ~= nil then
            result[k] = t[k]
        end
    end
    return result
end

api.login = function(user, password)
    local ctn = io.getFileContent("/Config/users")
    ctn = split(ctn, "\n")
    local device = k.devices.open("/data", "r")
    for _, v in pairs(ctn) do
        if string.sub(v, -1) == "\r" then
            v = string.sub(v, 0, -2)
        end
        
        local splitted = split(v, ":")

        local uid, username, hash, home, groups = table.unpack(splitted)
        local str = table.unpack(k.devices.ioctl(device, "sha256", password))
        local hashed = tohex(str)
        local result = hashed == hash and username == user
        ret = {result=result}
        if result then
            ret.groups = filterTable(api.readGroups(), split(groups, ","))
            ret.home = home
            ret.uid = uid
            return ret
        end
    end
    return {result=false}
end

return api