-- Prepare Screen and GPU

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
        k.devices.screen = component.proxy(screen)
        k.devices.gpu = gpu
    end
end

-- Load Modules
local files = component.invoke(computer.getBootAddress(), "list", "/System/Kernel/modules")
table.sort(files)

for _,file in ipairs(files) do
    local module, err = _G.lib.loadfile("/System/Kernel/modules/" .. file)
    if not module then
        error(err)
    end
    module()
end


k.threading.createThread("init", function()
    local sandbox = require("Sandbox")
    local env = sandbox.create_env({
        perm_check = false
    })
    _G.syscall = env.syscall
    _G.ioctl = env.ioctl

    local shell = require("Shell")
    
    local sh, err
    _G.filesystem = env.filesystem
    local sh, err = shell.connect("tty0")
    if not sh then
        k.panic(err)
    end
    sh:execute("/Bin/shell.lua")
    _G.syscall, _G.ioctl = nil, nil
end, 1):start()


k.printk(k.L_INFO, "Running CoreOS v" .. _G.VERSION_INFO.major .. "." .. _G.VERSION_INFO.minor .. "." .. _G.VERSION_INFO.micro .. "-".. _G.VERSION_INFO.release)
