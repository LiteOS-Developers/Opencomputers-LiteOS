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

function tab.loadtab()
    local stat = syscall("stat", "/etc/devtab")
    if not stat then return nil, errno.ENOENT end
    if not (stat.mode & 0x8000) then return nil, errno.ENOENT end
    local handle, err = syscall("open", "/etc/devtab", "r")
    if not handle then return nil, err end
    local content = ""
    local data
    repeat
        data = syscall("read", handle, 2048)
        content = content .. (data or "")
    until not data
    syscall("close", handle)
    lines = split(content, "\n")
    for k, line in ipairs(lines) do
        if line:sub(-1) == "\r" then line = line:sub(1, line:len() - 1) end
        all = split(line, ",")
        if #all ~= 3 then return errno.EINVAL end
        name, type_, addr = table.unpack(all)
        if type(name) ~= "string" or type(type_) ~= "string" or type(addr) ~= "string" then
            return nil, errno.EINVAL
        end
        local result, e = syscall("mknod", "/dev/"..name, type_, addr)
    end
    return true
end

