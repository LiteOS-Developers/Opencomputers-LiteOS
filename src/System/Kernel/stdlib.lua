local event = _G.lib.loadfile("/System/Lib/Event.lua")()

function _G.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

_G.table.keys = function(t)
    checkArg(1, t, "table")
    local r = {}
    for k, v in pairs(t) do
        _G.table.insert(r, k)
    end
    return r
end

_G.split = function(inputstr, sep)
    checkArg(1, inputstr, "string")
    checkArg(2, sep, "string")
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function _G.getFirst(t)
    for k, v in pairs(t) do
        return k, v
    end
end

function _G.getValueFromKey(t, k)
    for kt, v in pairs(t) do
        if kt == k then return v end
    end
end

function _G.inTable(t, k)
    for kt, v in pairs(t) do
        if v == k then return true end
    end
    return false
end

function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy, t
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            t = deepcopy(getmetatable(orig), copies)
            if type(t) == "table" or type(t) == "nil" then
                setmetatable(copy, t)
            end
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- k.keyCode, k.superKeys = _G.lib.loadfile("/System/keycodes.lua")() -- load keycodes and superkeys

function k.getKey()
    while true do
        local _, addr, char, code, player = table.unpack(event.pull("key_down"))
        local id = tostring(string.format("%.0f", char))
        local i = tonumber(id)
        local code = tonumber(string.format("%.0f", code))

        if i == 0 and code == 29 then return "STRG"
        elseif i == 0 and code == 157 then return "RSTRG"
        --[[elseif i == 0 and code == 42 or i == 0 and code == 54 then
            if #k.keys >= 2 then
                local char, code = k.keys[2].char, k.keys[2].code
                local id = tostring(string.format("%.0f", char))
                local i = tonumber(id)
                local code = tonumber(string.format("%.0f", code))
                return getValueFromKey(keyCode, id .. "." .. code)
            end--]]
        elseif i == 0 and code == 56 then return "ALT"
        elseif i == 0 and code == 58 then return "CAPSLOCK"
        elseif i == 0 and code == 219 then return "SUPER"
        elseif i == 8 and code == 14 then return "BACKSPACE" 
        elseif i == 9 and code == 15 then return "TAB"
        elseif i == 13 and code == 28 then return "ENTER"
        else
            local k = getValueFromKey(keyCode, id)
            return k
        end
        
        k.system.sleep(0.1)
    end
    return "<INVALID-KEY>"
end

function _G.rmFloat(n) 
    return tostring(string.format("%.0f", n))
end

return _G