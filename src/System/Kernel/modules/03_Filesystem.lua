-- k.printk(k.L_INFO, "Mouting filesystems...")
k.printk(k.L_INFO, " - 03_filesystem")


local drive0 = computer.getBootAddress()
k.devices.drive0 = component.proxy(drive0)

k.filesystem.mount(drive0, "/")
k.filesystem.mount(k.devices.addr, "/dev")
k.filesystem.mount(computer.tmpAddress(), "/tmp")
local driveId = 1

for addr, type in pairs(component.list("filesystem")) do
    if not addr == drive0 then
        k.devices["drive"..tostring(driveId)] = component.proxy(addr)
        k.devices.register("drive"..tostring(driveId), component.proxy(addr))
        driveId = driveId + 1
    end
    --filesystem.mount(addr, "/Mount/" .. addr)
end

-- k.printk(k.L_INFO, "Mouted filesystems...")