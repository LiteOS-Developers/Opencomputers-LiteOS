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
k.screen = {}
k.devices = {}
if gpu then 
    gpu = component.proxy(gpu)

    if gpu then
        if not gpu.getScreen() then 
            gpu.bind(screen)
        end
        local w, h = gpu.getResolution()
        k.screen.w = w
        k.screen.h = h
        gpu.setResolution(w, h)
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, w, h, " ")
        k.devices.screen = component.proxy(screen)
        k.devices.gpu = gpu
    end
end

k.println = function(line)
    lib.log_to_screen(line)
    return
    -- msg = msg or ""
    -- if k.devices.gpu then
    --     local sw, sh = k.devices.gpu.getResolution() 
    --     for l in split(line, "\n") do
    --         k.devices.gpu.set(k.screen.x, k.screen.y, l)
    --         if k.screen.y == sh then
    --             k.devices.gpu.copy(1, 2, sw, sh - 1, 0, -1)
    --             k.devices.gpu.fill(1, sh, sw, 1, " ")
    --         else
    --             k.screen.y = k.screen.y + 1
    --         end
    --         k.screen.x = 1
    --     end
    --     -- k.screen.x = k.screen.x + string.len(msg)
    -- end
end

k.getGPU = function() return gpu end
k.getScreen = function() return screen end