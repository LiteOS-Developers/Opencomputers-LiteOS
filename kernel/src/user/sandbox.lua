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
        k.printf("%s:%d: %s\n", info.short_src, tostring(info.currentline), l)
        for _, line in ipairs(split(debug.traceback(), "\n")) do
            line = line:gsub("\t", "  ")
            k.printf("%s\n", line)
        end
        local proc = k.current_process()
        proc.is_dead = true
        coroutine.yield()
    end
    new.printf = function(format, ...)
        k.printf(format, ...)
    end

    errno = deepcopy(k.errno)

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

    
    local yield = new.coroutine.yield
    function new.coroutine.yield(request, ...)
        local proc = k.current_process()
        local last_yield = proc.last_yield or computer.uptime()

        -- local info = debug.getinfo(3)
        -- k.printk(k.L_DEBUG, "%s:%.0f (%s)", info.short_src, info.currentline, info.name)

        if request == "syscall" then
            if computer.uptime() - last_yield > k.max_proc_time then
                --coroutine.yield(k.sysyield_string)
                proc.last_yield = computer.uptime()
            end
            
            return table.unpack(table.pack(k.perform_system_call(...)))
        end
        
        proc.last_yield = computer.uptime()
        if request == nil then
            return yield(k.sysyield_string)
        end
        return yield(request, ...)
    end

    function new.ioctl(fd, func, ...)
        return table.unpack(table.pack(new.syscall("ioctl", fd, func, ...)))
    end

    function new.syscall(call, ...)
        return table.unpack(table.pack(new.coroutine.yield("syscall", call, ...)))
    end
    
    return new
end
