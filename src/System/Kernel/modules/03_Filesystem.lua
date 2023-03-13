k.write("Mouting filesystems...")

local drive0 = computer.getBootAddress()
_G.k.devices.drive0 = component.proxy(drive0)
_G.k.filesystem.mount(computer.getBootAddress(), "/")
local driveId = 1
for addr, type in pairs(component.list("filesystem")) do
    if not addr == drive0 then
        _G.k.devices["drive"..tostring(driveId)] = component.proxy(addr)
        driveId = driveId + 1
    end
    --filesystem.mount(addr, "/Mount/" .. addr)
end

    k.write("Mouted filesystems...")