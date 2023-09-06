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

--#define INIT_SCREEN

local screen = component.list("screen", true)()
local gpu = screen and component.list("gpu", true)()
k.devices = {}
if gpu then 
    gpu = component.proxy(gpu)

    if gpu then
        if not gpu.getScreen() then 
            gpu.bind(screen)
        end
        local w, h = gpu.getResolution()
        k.cursor:init(1, 1, w, h)
        gpu.setResolution(w, h)
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, w, h, " ")
        k.devices.screen = component.proxy(screen)
    end
end

function k.setText(x, y, text)
    local w, h = gpu.getResolution()
    gpu.fill(x, y, w-x, 1, " ")
    gpu.set(x, y, text:sub(1, w-x))
end

k.printf = function(fmt, ...)
    local msg = string.format(fmt, ...)
    if gpu then
        local sw, sh = k.cursor.width, k.cursor.height
        local lines = split(msg, "\n")
        for idx, l in pairs(lines) do
            l = l:gsub("\t", "  ")
            -- lib.log_to_screen(dump(sh))
            gpu.set(k.cursor:getX(), k.cursor:getY(), l)
            if k.cursor:getY() == k.cursor.height then
                gpu.copy(1, 2, sw, sh - 1, 0, -1)
                gpu.fill(1, sh, sw, 1, " ")
            end
            if #lines > idx then
                k.cursor:incy(1)
            end
        end
        if msg:sub(-1, -1) ~= "\n" then
            k.cursor:incx(string.len(lines[#lines]))
        else
            k.cursor:move(1)
            if k.cursor:getY() < k.cursor.height then   
                k.cursor:incy(1)
            end
        end
    end
    k.debug(msg)
end

k.getGPU = function() return gpu end
k.getScreen = function() return screen end