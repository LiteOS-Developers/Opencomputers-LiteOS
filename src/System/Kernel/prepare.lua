local screen = component.list("screen", true)()
local gpu = screen and component.list("gpu", true)()

if gpu then 
    gpu = component.proxy(gpu)

    if gpu then
        if not gpu.getScreen() then 
            gpu.bind(screen)
        end
        local w, h = gpu.getResolution()
        _G.screen.w = w
        _G.screen.h = h
        gpu.setResolution(w, h)
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, w, h, " ")
        _G.screen.screen = component.proxy(screen)
        _G.screen.gpu = gpu
    end
end
if computer.getArchitecture() ~= "Lua 5.3" then
    error("Failed to Boot: OS requires Lua 5.3")
    _G.computer.shutdown()
end