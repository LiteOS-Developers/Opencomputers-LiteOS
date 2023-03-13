k.write("Loading components...")

local fs = k.service.getService("filesystem")

datacard = component.list("data")()
if datacard == nil then
    error("No DataCard Avaiable!")
end
k.devices.data = component.proxy(datacard)

_G.table.keys = function(table)
    local r = {}
    for k, v in pairs(table) do
        _G.table.insert(r, k)
    end
    return r
end
k.write("Loaded components")
