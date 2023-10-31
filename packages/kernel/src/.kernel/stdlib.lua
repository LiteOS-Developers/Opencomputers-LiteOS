local event = _G.lib.loadfile("/System/Lib/Event.lua")()

function k.write(msg, newLine)
    msg = msg == nil and "" or msg
    newLine = newLine == nil and true or newLine
    if k.devices.gpu then
        local sw, sh = k.devices.gpu.getResolution() 

        k.devices.gpu.set(k.screen.x, k.screen.y, msg)
        if k.screen.y == sh and newLine == true then
            k.devices.gpu.copy(1, 2, sw, sh - 1, 0, -1)
            k.devices.gpu.fill(1, sh, sw, 1, " ")
        else
            if newLine then
                k.screen.y = k.screen.y + 1
            end
        end
        if newLine then
            k.screen.x = 1
        else
            k.screen.x = k.screen.x + string.len(msg)
        end
    end
end

function _G.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        if type(o) == "string" then return string.format("'%s'", tostring(o)) end
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

table.contains = function(t, val)
    for _, v in pairs(t) do
        if v == val then return true end
    end
    return false
end

function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
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



return _G