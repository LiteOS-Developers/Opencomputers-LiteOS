--#skip 13
--[[
    Copyright (C) 2023 thegame4craft

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

k.threading = {}

k.threading.threads = {}
k.threading.running = nil

k.threading.getCurrent = function()
    local coro, main = coroutine.running()
    -- error({coro, main})
    for pid, t in pairs(k.threading.threads) do
        if t.coro == coro then
            return t
        end
    end
end

k.threading.createThread = function(name, func, pid)
    checkArg(1, name, "string")
    checkArg(2, func, "function")
    checkArg(3, pid, "number", "nil")

    if pid ~= nil then
        if not (0 < tonumber(pid)) or not (tonumber(pid) < 65536) then error("Bad argument #3 (expected Range 1 to 65535, got " .. tostring(pid) .. ")") end
        if k.threading.threads[pid] ~= nil and k.threading.threads[pid].stopped ~= true then error("Thread already exists") end
    end

    local thread = {}
    thread.func = func
    thread.name = name
    thread.coro = nil
    thread.result = nil
    thread.pid = pid or k.threading.generatePid()
    thread.created = computer.uptime()

    function thread:stop()
        k.threading.threads[self.pid].stopped = true
        k.threading.threads[self.pid].started = computer.uptime()
    end
    function thread:start()
        self.coro = coroutine.create(self.func)
        k.threading.threads[self.pid] = thread
    end

    return thread
end

k.threading.generatePid = function()
    local pid
    repeat 
        pid = math.random(100, 65500)
    until type(k.threading.threads[pid]) == "nil"
    return pid
end