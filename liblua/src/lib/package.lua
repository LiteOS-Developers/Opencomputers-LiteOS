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

local package = {
    searchPaths = {
        "/lib/?.lua",
        "/lib/?/init.lua",
        "/lib/?/?.lua",
        "/usr/lib/?.lua",
        "/usr/lib/?/init.lua",
        "/usr/lib/?/?.lua",
    },
    loaded = {}
}

package.load = function(name)
    if #package.searchPaths == 0 then return nil end
    if package.loaded[name] ~= nil then return package.loaded[name] end
    for _, path in ipairs(package.searchPaths) do
        path = path:gsub("?", name)
        local stat = syscall("stat", path)
        if stat and stat.mode & 0x8000 then
            local data = ""
            local chunk
            local handle, e = syscall("open", path, "r")

            if not handle then return nil, e end
            repeat
                chunk = syscall("read", handle, 128)
                data = data .. (chunk or "")
            until not chunk
            -- error("!")
            syscall("close", handle)
            local l, err = load(data, "=" .. path, "bt")
            if not l then
                error(err)
            end
            package.loaded[name] = l()
            return package.loaded[name]
        end
    end
    return nil
end

return package
