local api = {
    components = {}
}
local native = component

local function tableMerge(t1, t2)
    local result = t1
    for k, v in pairs(t2) do result[k] = v end
    return result
end

api.invoke = function(addr, method, ...)
    checkArg(1, address, "string")
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
    local result = {}
    -- if exact then
    for k, j in pairs(tableMerge(native.list(), api.components)) do
        if (api.type(k) == filter and exact) or string.sub(api.type(k), 1, #exact) == exact then
            result[k] = api.type(k)
        end
    end
    local i = 0
    return function()
        i = i + 1
        return result[i]
    end
end

api.proxy = function(addr)
    if inTable(addr, api.components) then
        return api.components[addr].api
    end
    return native.proxy(addr) 
end

api.type = function(addr)
    if inTable(addr, api.components) then
        return api.components[addr].type_
    end
    return native.type(addr) 
end

api.register = function(addr, name, type_, calls)
    api.components[addr] = {
        name=name,
        type_=type,
        api=calls
    }
end

api.isVirtual = function(addr)
    return api.components[addr] ~= nil
end