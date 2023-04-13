local api = {}

local function tobyte(int)
    checkAttr(1, int, "number")
    local t = {}
    for i = 0, 7 do
        t[i+1] = (int >> (i * 8)) & 0xFF
    end
end

local function max(max, v) 
    checkArg(1, max, "number")
    checkArg(2, v, "number")
    if max < v then
        return max
    end
    return v
end

local function trunc(str, len)
    checkArg(1, str, "string")
    checkArg(2, len, "number")
    if str:len() == len then return str end
    if str:len() > len then return string.sub(str, 1, len) end
    local toFill = max(len, tonumber(math.abs(len - string.len(str))))
    repeat
        str = str .. " "
        toFill = toFill - 1
    until toFill == 0
    return str
end

local function unsign(value, bits)
    if value > 0 then return value end
    return (1 << bits) + value
end

local function trim(str)
    repeat
        str = str:sub(1, -2)
    until str:sub(-1, -1) ~= " "
    return str
end

api.readUint = function(addr, off)
    checkArg(1, addr, "string")
    checkArg(2, off, "number")
    return string.unpack("B", string.pack("B", component.invoke(addr, "readByte", off) & 0xFF))
end

api.readChars = function(addr, off, size)
    checkArg(1, addr, "string")
    local str = ""
    for i = 0, size-1 do
        str = str .. string.pack("B", math.abs(component.invoke(addr, "readByte", off+i)))
    end
    return str
end

api.readUint2 = function(addr, off)
    checkArg(1, addr, "string")
    local lo = api.readUint(addr, off)
    local hi = api.readUint(addr, off+1)
    return hi << 8 | lo
end

api.writeChars = function(addr, off, value)
    for i=0, value:len()-1 do
        api.writeUint(addr, off+i, string.byte(value:sub(i+1,i+1)))
    end
end

api.readUint4 = function(addr, off)
    checkArg(1, addr, "string")
    local value = api.readUint(addr, off)
    value = value | api.readUint(addr, off+1) << 8
    value = value | api.readUint(addr, off+2) << 16
    value = value | api.readUint(addr, off+3) << 24
    return value
end

api.writeUint = function(addr, off, value)
    checkArg(1, addr, "string")
    checkArg(2, off, "number")
    checkArg(3, value, "number")
    return component.invoke(addr, "writeByte", off, value & 0xFF)
end

api.writeUint2 = function(addr, off, value)
    checkArg(1, addr, "string")
    api.writeUint(addr, off, value & 0xFF)
    api.writeUint(addr, off+1, (value & 0xFF00) >> 8)
end
api.writeUint4 = function(addr, off, value)
    checkArg(1, addr, "string")
    api.writeUint(addr, off, value & 0xFF)
    api.writeUint(addr, off+1, (value & 0xFF00) >> 8)
    api.writeUint(addr, off+2, (value & 0xFF0000) >> 16)
    api.writeUint(addr, off+3, (value & 0xFF000000) >> 24)
end

api.getNextFreeSector = function(addr, count)
    checkArg(1, addr, "string")
    -- local partitions = api.read(addr).partitions
    -- if #partitions == 0 then return 3 end
    -- for idx, p in ipairs(partitions) do
    --     if idx < #partitions then
    --         local overalloc = partitions[idx+1].firstSector - (p.firstSector + p.size)
    --         if overalloc > 0 then
    --             error(string.format("Overallocation at %s by %.0f sectors ", tostring(p.firstSector), overalloc))
    --         end
    --         if partitions[idx+1].firstSector - (p.firstSector + p.size) >= count then
    --             return p.firstSector + p.size
    --         end
    --     end
    -- end
    -- return partitions[#partitions].firstSector + partitions[#partitions].size
    local free = api.listFreeSpace(addr)
    if #free == 1 and free[1].count == 0 then return nil, "No Space Left"
    else
        for idx, v in ipairs(free) do
            if v.count >= count then
                return v.begin
            end
        end
    end
    return nil, "Not enough Space Left"
end

api.listFreeSpace = function(addr)
    local sectors = {}
    local data = api.read(addr)
    local partitions = data.partitions
    local last = partitions[1]
    for idx, p in ipairs(partitions) do
        if idx < #partitions then
            local overalloc = partitions[idx+1].firstSector - (p.firstSector + p.size)
            if overalloc > 1 then
                error(string.format("Overallocation between %s and %s by %.0f sectors ", tostring(p.firstSector), partitions[idx+1].firstSector, overalloc))
            end
            if overalloc >= 2 then
                sectors[#sectors + 1] = {begin = p.firstSector + p.size + 1, count = overalloc}
            end
        end
        if not last then last = deepcopy(p)
        elseif p.firstSector > last.firstSector then last = deepcopy(p) end
    end
    if not last then 
        return {
            {
                begin = 3,
                count = data.total_sector_count - 3
            }
        }
    end

    if data.total_sector_count - (last.firstSector + last.size) - 4 > 0 then
        sectors[#sectors + 1] = {begin = last.firstSector + last.size + 1, count = data.total_sector_count - (last.firstSector + last.size) - 4}
    end
    
    return sectors
end

api.list = function()
    local d = {}
    for a, v in component.list("drive") do
        d[#d+1] = a
    end
    return d
end

api.getNameOf = function(addr)
    checkArg(1, addr, "string")
    return component.getName(addr)
end

api.readPartition = function(addr, off)
    checkArg(1, addr, "string")
    local data = {}
    data.attributes = api.readUint(addr, off)
    data.firstSector = api.readUint4(addr, off+1)
    data.partition_number = api.readUint(addr, off+5)
    data.partition_name = trim(api.readChars(addr, off+6, 5))
    data.type = api.readUint(addr, off+11)
    data.size = api.readUint4(addr, off+12)
    return data
end

api.read = function(addr)
    checkArg(1, addr, "string")
    local data = {
        partitions = {}
    }
    data.sector_size = api.readUint2(addr, 1)
    if data.sector_size == 0 then data.sector_size = component.invoke(addr, "getSectorSize") end
    data.bootable = api.readUint(addr, 3)
    data.total_sector_count = api.readUint4(addr, 4)
    if data.total_sector_count == 0 then data.total_sector_count = component.invoke(addr, "getCapacity") / component.invoke(addr, "getSectorSize") end
    data.lpt = api.readChars(addr, 8, 5)
    local offs = {439, 455, 471, 487}
    for idx, o in pairs(offs) do
        if api.readUint(addr, o) ~= 0 then 
            data.partitions[#data.partitions+1] = api.readPartition(addr, o) 
        end
    end
    return data
    -- assert(sector_size == 512, tostring(sector_size))
end

api.createLPT = function(addr)
    checkArg(1, addr, "string")
    -- k.write(addr)
    component.invoke(addr, "writeSector", 1, string.rep("\0", 512))
    component.invoke(addr, "writeSector", 2, string.rep("\0", 512))
    api.writeUint2(addr, 1, 512)
    api.writeUint(addr, 3, 0)
    api.writeUint4(addr, 4, component.invoke(addr, "getCapacity") / component.invoke(addr, "getSectorSize"))
    api.writeChars(addr, 8, "LPT0 ")
    api.writeUint4(addr, 505, math.random(0x10000000, 0xFFFFFFFF))
    api.writeUint4(addr, 511, 0x55AA)
end

api.getEntryPos = function(addr)
    checkArg(1, addr, "string")
    local offs = {439, 455, 471, 487}
    for idx, o in pairs(offs) do
        if api.readUint(addr, o) == 0 then return o, idx end
    end
    local i = 513
    local idx = 5
    while i < 1025 do
        if api.readUint(addr, i) == 0 then return i, idx end
        i = i + 16
        idx = idx + 1
    end
    return nil, "No Free Entry"
end

api.createPartition = function(addr, name, size, attrs, firstSector, type)
    checkArg(1, addr, "string")
    checkArg(2, name, "string")
    checkArg(3, size, "number")
    checkArg(4, attrs, "number")
    checkArg(5, firstSector, "number")
    checkArg(6, type, "number")
    local entryPos,e = api.getEntryPos(addr)
    if not entryPos then return nil, e end
    k.write(string.format("Create %s at %.0f with %.0f sectors", name, firstSector, size))
    name = trunc(name, 5)

    api.writeUint(addr, entryPos, attrs & 0x17 | 0x20)
    api.writeUint4(addr, entryPos+1, firstSector)
    api.writeUint(addr, entryPos+5, tonumber(e))
    api.writeUint(addr, entryPos+6, string.byte(name:sub(1,1)))
    api.writeUint(addr, entryPos+7, string.byte(name:sub(2,2)))
    api.writeUint(addr, entryPos+8, string.byte(name:sub(3,3)))
    api.writeUint(addr, entryPos+9, string.byte(name:sub(4,4)))
    api.writeUint(addr, entryPos+10, string.byte(name:sub(5,5)))
    api.writeUint(addr, entryPos+11, type)
    api.writeUint4(addr, entryPos+12, size)
    return true
end

api.removePartition = function(addr, n)
    local offs = {439, 455, 471, 487}
    for idx, o in pairs(offs) do
        local number = api.readUint(addr, o+5)
        if number == n then
            for i=0,15 do
                -- k.write(tostring(o+i))
                api.writeUint(addr, o+i, 0)
            end
            break
        end
    end
end
return api