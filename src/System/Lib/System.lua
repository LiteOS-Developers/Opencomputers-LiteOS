local system = {}

local fs = _G.service.getService("filesystem")

system.sleep = function(timeout)
    local deadline = computer.uptime() + (timeout or 0)
    repeat
        coroutine.yield()
    until computer.uptime() >= deadline
end

system.sleepK = function(timeout)
    local deadline = computer.uptime() + (timeout or 0)
    repeat
        computer.pullSignal(deadline - computer.uptime())
    until computer.uptime() >= deadline
end

system.executeFile = function(path, env)
    if env == nil then 
        env = _G
    end
    if fs.isFile(path) then
        local file = fs.open(path, "r")
        local data = ""
        local content
        repeat
            content = fs.read(file, math.huge)
            data = data .. (content or "")
        until not content
        fs.close(file)
        
        local l, e = load(data, "=" .. path, "bt", env)

        if l == nil or e ~= nil then
            write("Error:".. e)
        end
        
        res = l()
        return res
    end
    error("FileNotFound: " .. path)
    return nil
end

return system