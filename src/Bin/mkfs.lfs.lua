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

local writeUint = function(handle, off, value)
    checkArg(1, handle, "number")
    checkArg(2, off, "number")
    checkArg(3, value, "number")
    return ioctl(handle, "writeByte", off, value & 0xFF)
end

local writeUint2 = function(handle, off, value)
    checkArg(1, handle, "number")
    writeUint(handle, off, value & 0xFF)
    writeUint(handle, off+1, (value & 0xFF00) >> 8)
end
local writeUint4 = function(handle, off, value)
    checkArg(1, handle, "number")
    writeUint(handle, off, value & 0xFF)
    writeUint(handle, off+1, (value & 0xFF00) >> 8)
    writeUint(handle, off+2, (value & 0xFF0000) >> 16)
    writeUint(handle, off+3, (value & 0xFF000000) >> 24)
end

local writeChars = function(handle, off, value)
    for i=0, value:len()-1 do
        writeUint(handle, off+i, string.byte(value:sub(i+1,i+1)))
    end
end

return {
    main = function(args)
        local drives = require("system.Drives")
        if not drives then
            print("mkfs.lfs: Requires elevated Rights")
            return -1
        end
        assert(drives, "FAIL!")
        local partition = "/dev/hd0p0"

        local device, partitionNr = partition:match("/dev/(hd[%d]+)p([%d]+)$")
        print(device)
        print(partitionNr)

        local partitions = drives.read(drives.getAddrOf(device)).partitions
        local current
        for _, p in pairs(partitions) do
            if p.partition_number == tonumber(partitionNr) + 1 then
                current = p
            end
        end
        if not current then
            print("mkfs.lfs: Partition does not exists!")
            return -1
        end
        if current.type ~= 1 then
            print("mkfs.lfs: Trying to mkfs.lfs on invalid partition type")
            return -1
        end
        -- print(dump(partitions))
        -- if true then return 0 end

        local drive, e = filesystem.open(partition)
        local cursor = filesystem.open("/dev/cursor")
        if not drive then
            print("mkfs.lfs: " .. dump(e))
            return -1
        end
        

        local x, y = ioctl(cursor, "get")
        local sectors = (ioctl(drive, "getCapacity") / ioctl(drive, "getSectorSize"))
        local data = string.rep("\0", 512)
        local start = computer.uptime()
        ioctl(drive, "writeSector", 1, data)
        writeUint4(drive, 1, sectors)
        writeUint4(drive, 21, math.random(0x10000000, 0xFFFFFFF0), current.firstSector + 1)

        -- Root directory
        local currentTime = tonumber(string.format("%.0f", time()/1000))
        writeUint4(drive, 512+1, 0xFFFFFFFF)
        writeUint4(drive, 512 + 5, currentTime)
        writeUint (drive, 512 + 9, 0)
        
        -- FileA
        writeUint(drive, 512 + 10, 1 << 5)
        writeUint4(drive, 512 + 11, currentTime)
        writeUint4(drive, 512 + 15, 0)
        writeUint4(drive, 512 + 19, 2)
        writeChars(drive, 512 + 23, "FileA     ")
        writeChars(drive, 512 + 33, "txt")
        writeUint2(drive, 512 + 35, (1 << 9) - 1)
        writeUint2(drive, 512 + 38, 0)
        writeUint2(drive, 512 + 40, 0)

        writeUint4(drive, 1024+1, 0xFFFFFFFF)
        writeUint4(drive, 1024+5, currentTime)
        writeUint (drive, 1024+9, 0)
        
        filesystem.close(drive)
        
    end
}