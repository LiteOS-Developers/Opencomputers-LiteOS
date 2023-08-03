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

k.printk(k.L_INFO, "user/exec")

function k.loadfile(file, env)
    local buf = ""
    local chunk
    local handle = k.rootfs.open(file, "r")
    repeat
        chunk = k.rootfs.read(handle, math.huge)
        buf = buf .. (chunk or "")
    until not chunk
    k.rootfs.close(handle)
    return load(buf, "=" .. file, "t", env)
end

k.exec = function(file, args)
    args = args or {}
    table.insert(args, 1, file)
    local thread = k.create_thread(function() 
        local f = k.loadfile(file, k.current_process().env)()
        if not f.main then return nil end
        local r = f.main(args)
        if r == nil then r = 0
        elseif type(r) == "string" then r = tonumber(r) 
        else r = 0 end
        k.syscalls.exit(tonumber(r or "0") or 0)
    end)
    process = k.get_process(k.add_process())
    process.cmdline = args
    process:addThread(thread)
    while not process.is_dead do
        k.event.tick()
    end
    return process.status()
end
