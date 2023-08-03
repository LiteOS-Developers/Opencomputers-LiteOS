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

k.printk(k.L_INFO, "user/sandbox")
k.sandbox = {}

local function copyBlacklist(t, list)
    local new = deepcopy(t)
    for key in pairs(list) do new[key] = nil end
    return new
end


local blacklist = {
    k = true, lib = true, component = true, _G = true
}

k.max_proc_time = tonumber(k.cmdline.max_proc_time or "3") or 3

k.sandbox.new = function(opts)
    checkArg(1, opts, "table", "nil")
    opts = opts or {}
    opts.base = opts.base or _G

    local new = deepcopy(base or _G)
    for key, v in pairs(blacklist) do new[key] = nil end
    
    new.load = function(a, b, c, d)
        return loadfile(a, b, c, d or k.current_process().env)
    end
    new.error = function(l)
        local info = debug.getinfo(3)
        t = info.short_src .. ":" .. tostring(info.currentline) .. ": " .. l .. "\n" .. debug.traceback()
        k.io.stdout:writelines(t)
        local thread = k.threading.getCurrent()
        thread:stop()
        coroutine.yield()
    end
    new.print = function(...)
        k.printf(...)
    end

    -- new.time = k.time

    -- new.dofile = function(path)
    --     local res, e = dofile(path, new)
    --     if not res then
    --         return nil, e
    --     end
    --     return res
    -- end
    -- new.package = new.dofile("/Lib/Package.lua")
    -- new.require = function(p)
    --     local groups = (user or {}).groups or {}
    --     if p:sub(1,7):lower() == "system." and table.contains(groups, "0") then
    --         return k.package.require(p:sub(8))
    --     end
    --     return new.package.require(p) 
    -- end
    -- end

    new.computer = {
        uptime = computer.uptime,
        freeMemory = computer.freeMemory,
        totalMemory = computer.totalMemory,
    }

    new.io = {
        stdin = k.io.stdin
    }

    local function modeTable(m)
        checkArg(1, m, "string")
        local mode = {}
        for i = 1, unicode.len(m) do
            mode[unicode.sub(m, i, i)] = true
        end
        return mode
    end

    function new.checkAttrMode(attrs, useGroup)
        checkArg(1, attrs, "table")
        mode = attrs.mode
        assert(type(mode) == "string", "Bad Argument #1: table is Empty")
        assert(mode:len() >= 9, "Expected 'mode' of length 9 got " .. tostring(mode:len()))
        local result = {}
        if ((not user.uid or tonumber(attrs.uid) == user.uid) and mode:sub(1, 1) == "r") or mode:sub(7, 7) == "r" then result.r = true end
        if ((not user.uid or tonumber(attrs.uid) == user.uid) and mode:sub(2, 2) == "w") or mode:sub(8, 8) == "w" then result.w = true end
        if ((not user.uid or tonumber(attrs.uid) == user.uid) and mode:sub(3, 3) == "x") or mode:sub(9, 9) == "x" then result.x = true end
        if gid ~= nil and user.groups ~= nil then
            new.print(dump(user))
            if user.groups[gid] ~= nil then
                if mode:sub(4, 4) == "r" then result.r = true end
                if mode:sub(5, 5) == "w" then result.w = true end
                if mode:sub(6, 6) == "x" then result.x = true end
            end
        end
        return result
    end

    local yield = new.coroutine.yield
    function new.coroutine.yield(request, ...)
        local proc = k.current_process()
        local last_yield = proc.last_yield or computer.uptime()

        if request == "syscall" then
            if computer.uptime() - last_yield > k.max_proc_time then
                coroutine.yield(k.sysyield_string)
                proc.last_yield = computer.uptime()
            end
            
            return k.perform_system_call(...)
        end
        proc.last_yield = computer.uptime()
        return yield(request, ...)
    end
    
    return new
end
