local api = {}

if _G.services == nil then
    _G.services = {}
end


api.loadService = function(path)
    sName = path:sub(path:find("/[^/]*$") + 1)
    local ldp = (sName:reverse()):find("%.")
    sName = sName:reverse():sub(ldp+1):reverse()

    if _G.services[sName] ~= nil then
        return _G.services[sName], nil
    end
    local code = _G.lib.loadfile(path)

    if code == nil then
        return nil, "Could not load service: " .. path
    end
    local service = code()
    _G.services[sName] = service
    return service, nil
end

api.getService = function(sName)
    if _G.services[sName] ~= nil then
        return _G.services[sName]
    end 
    local service, err = api.loadService("/System/Services/" .. tostring(sName) .. ".lua")
    
    return service
end

api.unloadService = function(sName)
    _G.services[sName] = nil
end

return api