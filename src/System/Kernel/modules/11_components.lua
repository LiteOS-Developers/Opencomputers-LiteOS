-- k.printk(k.L_INFO,"Loading components...")
k.printk(k.L_INFO, " - 11_components")


local fs = k.service.getService("filesystem")

local datacard = component.list("data")()
if datacard == nil then
    error("No DataCard Avaiable!")
end

k.devices.register("data", component.proxy(datacard))
k.devices.register("cursor", {
    getX = function()
        return k.screen.x
    end,
    getY = function()
        return k.screen.y
    end,
    set = function(x, y)
        k.screen.x = x
        k.screen.y = y
    end,
    get = function()
        return k.screen.x, k.screen.y
    end 
})

local drives = {}
for addr, name in component.list("drive") do
    table.insert(drives, addr)
end
local drive = require("Drives")
for i, addr in pairs(drives) do
    k.devices.register("hd" .. tostring(i - 1), component.proxy(addr), {permissions = "r--r-----", size = component.invoke(addr, "getCapacity")})
    local drivedata = drive.read(addr)
    for key, value in ipairs(drivedata.partitions) do
        k.devices.register("hd"  .. tostring(i - 1) .. "p" .. string.format("%.0f", value.partition_number), 
        {
            readByte = function(offset) 
                return drive.readUint(addr, offset + value.firstSector * drivedata.sector_size)
            end,
            writeByte = function(offset, v) drive.writeUint(addr, offset + value.firstSector * drivedata.sector_size, v & 0xFF) end,
            getSectorSize = function() return drivedata.sector_size end,
            getLabel = function() return "p" .. string.format("%.0f", value.partition_number - 1) end,
            setLabel = function(value) error("Not Implemented") end,
            readSector = function(sector) return component.invoke(addr, "readSector", sector + value.firstSector) end,
            writeSector = function(sector, v)
                assert(type(v) == "string" and v:len() == drivedata.sector_size, 
                    "Bad Argument #2. Expected string(" .. tostring(drivedata.sector_size) .. "), got " .. type(v) .. " Value: " .. dump(v))
                component.invoke(addr, "writeSector", sector + value.firstSector, v)
            end,
            getPlatterCount = function() return 1 end,
            getCapacity = function() return drivedata.partitions[key].size * drivedata.sector_size end
        }, {size = drivedata.partitions[key].size * drivedata.sector_size})
    end
    component.setName(addr, "hd" .. tostring(i - 1))
end

k.devices.register("ps", {
    list = function()
        local processes = {}
        for pid, o in pairs(k.threading.threads) do
            if not o.stopped then
                table.insert(processes, o)
            end
        end
        return processes
    end
})
-- k.devices.register("events", k.event)

component.register(k.devices.addr, "devfs", k.devices)
-- k.printk(k.L_INFO, "Loaded components")
