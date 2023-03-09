local api = {}

api.threads = {}
api.running = nil

api.createThread = function(name, func)
    checkArg(1, name, "string")
    checkArg(2, func, "function")

    local thread = {}
    thread.func = func
    thread.name = name
    thread.coro = nil

    function thread:stop()
        api.threads[self.name] = nil
    end
    function thread:start()
        self.coro = coroutine.create(self.func)
        api.threads[self.name] = thread
    end

    return thread
end

return api