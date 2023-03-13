local screen = component.list("screen", true)()
local gpu = screen and component.list("gpu", true)()
k.screen = { y = 1, x = 1 }
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
        -- _G.k.screen = component.proxy(screen)
        k.devices.gpu = gpu
    end
end
if computer.getArchitecture() ~= "Lua 5.3" then
    error("Failed to Boot: OS requires Lua 5.3")
    _G.computer.shutdown()
end
_G.lib.loadfile("/System/Kernel/stdlib.lua")()

k.panic = function(e)
    k.devices.gpu.setForeground(0x990000)
    k.write(e)
    k.devices.gpu.setForeground(0xFFFFFF)
end
