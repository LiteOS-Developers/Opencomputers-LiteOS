k.write("Loading components...")

local fs = k.service.getService("filesystem")

datacard = component.list("data")()
if datacard == nil then
    error("No DataCard Avaiable!")
end

k.devices.register("data", component.proxy(datacard))

_G.table.keys = function(table)
    local r = {}
    for k, v in pairs(table) do
        _G.table.insert(r, k)
    end
    return r
end

_G.component = k.system.executeFile("/System/Kernel/components.lua")

component.register(k.devices.addr, "devfs", k.devices)
k.write("Loaded components")
