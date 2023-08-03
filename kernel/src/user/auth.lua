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

k.printk(k.L_INFO, "user/auth")
k.user = {}
local sha3 = k.require("sha3")
k.hostname = k.readfile("/etc/hostname")

function k.user.groups(username)
    local groups = k.readfile("/etc/group")
    local ugroup = {}
    for _, line in ipairs(split(groups, "\n")) do
        local data = split(line, ":")
        local g = {}
        g.name = data[1]
        g.gid = data[3]
        g.users = data[4]
        for _, user in ipairs(split(g.users, ",")) do
            if user == username then
                ugroup[#ugroup] = {name = g.name, gid = g.users}
                break
            end
        end
    end
    return ugroup
end

function k.user.match(username, password)
    local users = k.readfile("/etc/passwd")
    local user = {}
    for _, line in ipairs(split(users, "\n")) do
        local data = split(line, ":")
        user.name = data[1]
        local hashpw = data[2]
        user.uid = data[3]
        user.primGid = data[4]
        user.home = data[6]
        user.shell = data[7]
        if password == hashpw and username == username then
            user.groups = k.user.groups(username)
            return true, user
        end
    end
    return false, nil
end

function k.user.auth()
    k.printf("%s\n", dump(sha3))
    k.printf("%s login: ", k.hostname)
    local username = k.io.stdin:read()
    k.printf("Password: ")
    local password = sha3.sha512(k.getpass())
    local match, user = k.user.match(username, password)
    if match then
        return user
    else
        return nil
    end
end

