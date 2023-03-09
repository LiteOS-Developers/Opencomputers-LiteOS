local event = {}
_G.eventListeners = {}
event.cache = {}

event.register = function(name, func)
    local handler = {}
    handler.event = name
    handler.func = func

    if _G.eventListeners[name] ~= nil then
        table.insert(_G.eventListeners[name],handler)
        return
    end
    _G.eventListeners[name] = {handler}
end

event.listen = function(name, func)
    if _G.eventListeners[name] ~= nil then
        for _, handler in pairs(_G.eventListeners[name]) do
            if handler.name == name and handler.func == func then return false end
        end
    end
    return event.register(name, func)
end

event.pull = function(name, timeout)
    time = computer.uptime() + (timeout or 0.1)
    local signal = nil
    repeat
        signal = table.pack(computer.pullSignal())
        if _G.eventListeners[signal[1]] ~= nil then
            for _, handler in pairs(_G.eventListeners[name]) do
                if handler.name == name then
                    handler.func(table.unpack(signal, 1, signal.n))
                end
            end
        end
        if signal[1] == name then goto loopEnd end
        coroutine.yield()
    until signal[1] == name and computer.uptime() >= time
    ::loopEnd::
    if _G.eventListeners[name] ~= nil then
        for _, h in pairs(_G.eventListeners[name]) do
            h.func(table.unpack(signal, 1, signal.n))
        end
    end
    return table.pack(table.unpack(signal, 1, signal.n))
end

event.fetch = function(timeout)
    time = computer.uptime() + (timeout or 0.1)
    local signal = nil
    repeat
        signal = table.pack(computer.pullSignal())
        -- writeLog("Event: " .. signal[1])
        if _G.eventListeners[signal[1]] ~= nil then
            for _, handler in pairs(_G.eventListeners[signal[1]]) do
                if handler.event == signal[1] then
                    -- writeLog("Handler: " .. handler.event .. " Func: " .. tostring(handler.func))
                    handler.func(table.unpack(signal, 1, signal.n))
                end
            end
        end
        coroutine.yield()
    until computer.uptime() >= time
end

return event