k.printk(k.L_INFO,"Loading components...")

local fs = k.service.getService("filesystem")

datacard = component.list("data")()
if datacard == nil then
    error("No DataCard Avaiable!")
end

k.devices.register("data", component.proxy(datacard))
-- k.devices.register("events", k.event)



component.register(k.devices.addr, "devfs", k.devices)
k.printk(k.L_INFO, "Loaded components")
