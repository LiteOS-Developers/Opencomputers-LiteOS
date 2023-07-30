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
    checkArg(2, off, "number")
    checkArg(3, value, "number")
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
        local lfs = require("System.lfs")

        if not drives or not lfs then
            print("mkfs.lfs: Requires elevated Rights or missing libraries")
            return -1
        end
        assert(drives, "FAIL!")
        local partition = "/dev/hd0p1"

        local device, partitionNr = partition:match("/dev/(hd[%d]+)p([%d]+)$")
                
        -- print(dump(partitions))
        -- if true then return 0 end

        local drive, e = filesystem.open(partition)
        if not drive then
            print("mkfs.lfs: " .. dump(e))
            return -1
        end
        
        local sectors = (ioctl(drive, "getCapacity") / ioctl(drive, "getSectorSize"))
        local data = string.rep("\0", 512)
        local start = computer.uptime()
        ioctl(drive, "writeSector", 1, data)
        lfs.erase(partition)
        
        local success, e = lfs.createInitial(partition)
        if not success then
            print("mkfs.lfs: " .. dump(e))
            return -1
        end
        local currentTime = tonumber(string.format("%.0f", time()/1000))
        
        -- DirA
        writeUint (drive, 512 + 10, 1 << 5 | 1 << 4)
        writeUint4(drive, 512 + 11, currentTime)
        writeUint4(drive, 512 + 15, 0)
        writeUint4(drive, 512 + 19, 2)
        writeChars(drive, 512 + 23, "DirA     ")
        writeChars(drive, 512 + 33, "   ")
        writeUint2(drive, 512 + 36, (1 << 9) - 1)
        writeUint2(drive, 512 + 38, 0)
        writeUint2(drive, 512 + 40, 0)

        -- sec 2
        writeUint4(drive, 1024+1, 0xFFFFFFFF)
        writeUint4(drive, 1024+5, currentTime)
        writeUint (drive, 1024+9, 0)

        -- FileA 
        writeUint (drive, 1024 + 10, 1 << 5)
        writeUint4(drive, 1024 + 11, currentTime)
        writeUint4(drive, 1024 + 15, 11)
        writeUint4(drive, 1024 + 19, 3)
        writeChars(drive, 1024 + 23, "FileA     ")
        writeChars(drive, 1024 + 33, "txt")
        writeUint2(drive, 1024 + 36, (1 << 9) - 1)
        writeUint2(drive, 1024 + 38, 0)
        writeUint2(drive, 1024 + 40, 0)

        -- sec 3
        writeUint4(drive, 1536+1, 0xFFFFFFFF)
        writeUint4(drive, 1536+5, currentTime)
        writeUint (drive, 1536+9, 0)
        writeChars(drive, 1536+10, "Hello world from opencomputers using my own LiteOS filesystem")

    
        
        filesystem.close(drive)
        
    end
}