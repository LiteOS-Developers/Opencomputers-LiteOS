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

k.L_EMERG   = 0
k.L_ALERT   = 1
k.L_CRIT    = 2
k.L_ERROR   = 3
k.L_WARNING = 4
k.L_NOTICE  = 5
k.L_INFO    = 6
k.L_DEBUG   = 7
k.cmdline = {}
k.cmdline.loglevel = tonumber(k.cmdline.loglevel) or 8

local reverse = {}
for name,v in pairs(k) do
    if name:sub(1,2) == "L_" then
        reverse[v] = name:sub(3)
    end
end

function k.printk(level, fmt, ...)
    checkArg(1, level, "number")
    local message = string.format("[%08.02f] %s: ", computer.uptime(), reverse[level]) .. string.format(fmt, ...)

    if level <= k.cmdline.loglevel then
        k.write(message)
    end

    -- log_to_buffer(message)
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

return _G