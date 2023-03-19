local api = {}

api.packages = {}
api.searchPaths = {}

local fs = k.service.getService("filesystem")

api.load = function(name, api)
    checkArg(1, name, "string")
    checkArg(2, api, "table")
    if api.packages == nil then api.packages = {} end
    api.packages[name] = api
end

api.loadPackage = function(pName)
    checkArg(1, pName, "string")
    if not k.devices then
        return nil, "SystemError: Cannot find devices. The OS started may not correctly!"
    end

    if api.packages[pName] ~= nil then
        return api.packages[pName]
    end
    for _, v in pairs(api.searchPaths) do
        local rPath = v:gsub("?", pName)
        if fs.isFile(rPath) then
            local file = fs.open(rPath, "r")
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
                k.panic(e .. "\n" .. debug.traceback())
            end
            if l == nil then
                k.panic(dump(e))
            end
            
            -- _G.error(pName)
            api.packages[pName] = l()
            --_G.write(pName .. " " .. dump(_G.packages[pName]))  

            return api.packages[pName]
        end
    end
    k.panic("Failed to Load Module: " .. pName)
    return nil
end

api.addLibraryPath = function(path)
    checkArg(1, path, "string")
    table.insert(api.searchPaths, path)
end

api.addLibraryPath("/Lib/?.lua")
api.addLibraryPath("/Lib/?/init.lua")

api.require = api.loadPackage

return api