local api = {}

api.threads = {}
api.running = nil

api.createThread = function(name, func, args)
    checkArg(1, name, "string")
    checkArg(2, func, "function")
    checkArg(3, args, "table", "nil")

    local thread = {}
    thread.func = func
    thread.name = name
    thread.coro = nil
    thread.result = nil

    function thread:stop()
        api.threads[self.name].stopped = true
    end
    function thread:start()
        self.coro = coroutine.create(self.func)
        api.threads[self.name] = thread
    end

    return thread
end

return api