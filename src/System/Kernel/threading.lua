local api = {}

api.threads = {}
api.running = nil

api.createThread = function(name, func, pid)
    checkArg(1, name, "string")
    checkArg(2, func, "function")
    checkArg(3, pid, "number", "nil")

    if pid ~= nil then
        if not (0 < tonumber(pid)) or not (tonumber(pid) < 65536) then error("Bad argument #3 (expected Range 1 to 65535, got " .. tostring(pid) .. ")") end
        if api.threads[pid] ~= nil and api.threads[pid].stopped ~= true then error("Thread already exists") end
    end

    local thread = {}
    thread.func = func
    thread.name = name
    thread.coro = nil
    thread.result = nil
    thread.pid = pid or api.generatePid()
    thread.created = computer.uptime()

    function thread:stop()
        api.threads[self.pid].stopped = true
        api.threads[self.pid].started = computer.uptime()
    end
    function thread:start()
        self.coro = coroutine.create(self.func)
        api.threads[self.pid] = thread
    end

    return thread
end

api.generatePid = function()
    local pid
    repeat 
        pid = math.random(100, 65500)
    until type(api.threads[pid]) == "nil"
    return pid
end

return api