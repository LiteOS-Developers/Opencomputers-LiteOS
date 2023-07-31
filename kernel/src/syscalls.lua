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
--#define SYSCALLS
k.printk(k.L_INFO, "syscalls")
k.syscalls = {}

function k.perform_syscall(call, ...)
    checkArg(1, call, "string")
    if not k.syscalls[call] then
        return nil, k.errno.ENOSYS
    end
    local result = table.pack(pcall(k.syscalls[name], ...))
    return return table.unpack(result, result[1] and 2 or 1, result.n)
end

function k.register_syscall(call, f)
    checkArg(1, call, "string")
    checkArg(2, f, "function")
    k.syscalls[call] = f
end