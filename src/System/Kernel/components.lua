local api = {
    components = {}
}
local native = component

local function tableMerge(t1, t2)
    local result = t1
    for k, v in pairs(t2) do result[k] = v end
    return result
end

api.hasMethod = function(addr, method)
    checkArg(1, addr, "string")
    checkArg(2, method, "string")
    if api.components[addr] ~= nil then
        return api.components[addr].api[method] ~= nil
    end
    return native.methods(addr)[method] ~= nil
end

api.invoke = function(addr, method, ...)
    checkArg(1, addr, "string")
    checkArg(2, method, "string")
    if api.components[addr] ~= nil then
        if api.components[addr].api[method] ~= nil then
            return api.components[addr].api[method](...)
        end
    end
    return native.invoke(addr, method, ...)
end

api.list = function(filter, exact)
    checkArg(1, filter, "string", "nil")
    checkArg(2, exact, "boolean", "nil")
    exact = exact or false
    return native.list(filter, exact)
end

api.proxy = function(addr)
    if inTable(api.components, addr ) then
        return api.components[addr].api
    end
    return native.proxy(addr) 
end

api.type = function(addr)
    if inTable(api.components, addr) then
        return api.components[addr].type_
    end
    return native.type(addr) 
end

api.register = function(addr, type_, calls)
    api.components[addr] = {
        type_=type,
        api=calls
    }
end

api.isVirtual = function(addr)
    return api.components[addr] ~= nil
end

return api