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

_G.split = function(inputstr, sep)
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

keyCode, superKeys = _G.lib.loadfile("/System/keycodes.lua")() -- load keycodes and superkeys

function _G.getKey()
    while true do
        local _, addr, char, code, player = table.unpack(event.pull("key_down"))
        local id = tostring(string.format("%.0f", char))
        local i = tonumber(id)
        local code = tonumber(string.format("%.0f", code))

        if i == 0 and code == 29 then return "STRG"
        elseif i == 0 and code == 157 then return "RSTRG"
        elseif i == 0 and code == 42 or i == 0 and code == 54 then
            if #_G.keys >= 2 then
                local char, code = _G.keys[2].char, _G.keys[2].code
                local id = tostring(string.format("%.0f", char))
                local i = tonumber(id)
                local code = tonumber(string.format("%.0f", code))
                return getValueFromKey(keyCode, id .. "." .. code)
            end
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
        
        system.sleep(0.1)
    end
    return "<INVALID-KEY>"
end

function _G.rmFloat(n) 
    return tostring(string.format("%.0f", n))
end

function _G.write(msg, newLine)
    msg = msg == nil and "" or msg
    newLine = newLine == nil and true or newLine
    if _G.screen.gpu then
        local sw, sh = _G.screen.gpu.getResolution() 

        _G.screen.gpu.set(_G.screen.x, _G.screen.y, msg)
        if _G.screen.y == sh and newLine == true then
            _G.screen.gpu.copy(1, 2, sw, sh - 1, 0, -1)
            _G.screen.gpu.fill(1, sh, sw, 1, " ")
        else
            if newLine then
                _G.screen.y = _G.screen.y + 1
            end
        end
        if newLine then
            _G.screen.x = 1
        else
            _G.screen.x = _G.screen.x + string.len(msg)
        end
    end
end


return _G