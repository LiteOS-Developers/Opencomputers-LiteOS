local api = {}

_G.packages = {}
local searchPaths = {}

local fs = _G.service.getService("filesystem")

api.loadPackage = function(pName)
    checkArg(1, pName, "string")
    if not _G.devices then
        return nil, "SystemError: Cannot find devices. The OS started may not correctly!"
    end

    if not _G.devices.drive0 then
        return nil, "SystemError: Cannot find root drive. The OS started may not correctly!"
    end

    if packages[pName] ~= nil then
        return packages[pName]
    end

    for k, v in pairs(searchPaths) do
        local rPath = v:gsub("?", pName)
        if fs.isFile(rPath) then
            local file = fs.open(rPath, "r")
            _G.write(dump(file))
            local data = ""
            local content
            repeat
                content = fs.read(file, math.huge)
                if content ~= nil then
                    data = data .. content
                end
            until not content
            fs.close(file)
            -- error(data)
            local l, e = load(data, "=" .. rPath)
            if e ~= nil then
                _G.error(e .. "\n" .. debug.traceback())
            end
            if l == nil then
                _G.error(dump(e))
            end
            
            -- _G.error(pName)
            -- packages[pName] = l()
            --_G.write(pName .. " " .. dump(_G.packages[pName]))  

            return l()
        end
    end
    error("No File")
    return nil
end

api.addLibraryPath = function(path)
    checkArg(1, path, "string")
    table.insert(searchPaths, path)
end

api.addLibraryPath("/Lib/?.lua")
api.addLibraryPath("/Lib/?/init.lua")

api.require = api.loadPackage

return api