local api = {}

local ioctl = function(handle, ...) 
    return table.unpack(k.devices.ioctl(k.filesystem.getRealHandle(handle), ...))
end

local drives = require("Drives")
local function trim(str)
    if string.byte(str:sub(-1,-1)) ~= 32 then
        if string.byte(str:sub(-1,-1)) == 0 then return trim(str:sub(1, -2)) end
        local info = debug.getinfo(3)
        return str
    end
    repeat
        str = str:sub(1, -2)
    until str:sub(-1, -1) ~= " "
    return str
end

local function open(base)
    local device, partitionNr = base:match("/dev/(hd[%d]+)p([%d]+)$")
    local partition = drives.getPartitionByNumber(drives.getAddrOf(device), tonumber(partitionNr))
    local diskInfo = drives.read(drives.getAddrOf(device))
    if not partition then
        return nil, "Partition does not exists"
    end
    local devicename = string.format("/dev/%sp%d", device, partitionNr)
    local file, e = k.filesystem.open(devicename)
    if not file then
        return nil, e
    end
    return file
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
    if len - string.len(str) < 0 then str = string.sub(str, 1, len) end
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

local readUint = function(handle, off)
    checkArg(1, handle, "number")
    checkArg(2, off, "number")
    return string.unpack("B", string.pack("B", ioctl(handle, "readByte", off) & 0xFF))
end

local readUint2 = function(handle, off, value)
    checkArg(1, handle, "number")
    checkArg(2, off, "number")
    local value =  readUint(handle, off) | readUint(handle, off+1) << 8
    return value
end
local readUint4 = function(handle, off, value)
    checkArg(1, handle, "number")
    checkArg(2, off, "number")
    local value =  readUint(handle, off)
    value = value | readUint(handle, off+1) << 8
    value = value | readUint(handle, off+2) << 16
    value = value | readUint(handle, off+3) << 24
    return value
end

local readChars = function(handle, off, count)
    local str = ""
    for i=0, count-1 do
        str = str .. string.pack("B", readUint(handle, off+i))
    end
    return str
end

api.erase = function(device)
    local drive,e = open(device)
    if not drive then return false, e end
    local content = string.rep("\0", 512)
    for i = 1, 128 do
        ioctl(drive, "writeSector", i, content)
    end
end

api.read = function(base)
    checkArg(1, base, "string")
    local device, partitionNr = base:match("/dev/(hd[%d]+)p([%d]+)$")
    local partition = drives.getPartitionByNumber(drives.getAddrOf(device), tonumber(partitionNr))
    local diskInfo = drives.read(drives.getAddrOf(device))
    
    if not partition then
        return nil, "Partition does not exists"
    end
    local devicename = string.format("/dev/%sp%d", device, partitionNr)
    local file, e = k.filesystem.open(devicename)
    if not file then
        return nil, e
    end
    local data = {}
    data.sectorCount = readUint4(file, 1)
    data.signature = readUint4(file, 21)
    data.rootDirStart = readUint4(file, 25)
    data.rootDirOff = data.rootDirStart - partition.firstSector
    
    data.rootDirSectors = api.getSectors(devicename, data.rootDirOff)
    data.rootDirEntries = api.getEntries(devicename, data.rootDirSectors)
    return data
end

api.getSectors = function(base, begin)
    checkArg(1, base, "string")
    checkArg(2, begin, "number")

    local device, partitionNr = base:match("/dev/(hd[%d]+)p([%d]+)$")
    local partition = drives.getPartitionByNumber(drives.getAddrOf(device), tonumber(partitionNr))
    local diskInfo = drives.read(drives.getAddrOf(device))
    if not partition then
        return nil, "Partition does not exists"
    end
    local file, e = k.filesystem.open(string.format("/dev/%sp%d", device, partitionNr))
    if not file then
        return nil, e
    end
    local sectors = {begin}
    local i = begin
    while true do
        local next = readUint4(file, i * diskInfo.sector_size + 1)
        if next == 0xFFFFFFFF then break end
        i = next
        sectors[#sectors+1] = next
    end
    return sectors
end



api.getEntries = function(base, sectors)
    checkArg(1, base, "string")
    checkArg(2, sectors, "table")

    local device, partitionNr = base:match("/dev/(hd[%d]+)p([%d]+)$")
    local partition = drives.getPartitionByNumber(drives.getAddrOf(device), tonumber(partitionNr))
    local diskInfo = drives.read(drives.getAddrOf(device))
    if not partition then
        return nil, "Partition does not exists"
    end
    local file, e = k.filesystem.open(string.format("/dev/%sp%d", device, partitionNr))
    if not file then
        return nil, e
    end

    local entries = {}
    for key, value in ipairs(sectors) do
        local data = {}
        local lfnCount = readUint(file, value*diskInfo.sector_size + 9)
        assert(lfnCount == 0, "lfnCount is not 0")
        local count = math.floor((512 - 9 - 23 - lfnCount) / 32)
        for i = 0, 14 do
            local off = value*diskInfo.sector_size + i*32 + 10
            data = {}
            data.attributes = readUint(file, off)
            if data.attributes == 0 then break end
            data.lastAccess = readUint4(file, off+1)
            data.size = readUint4(file, off+5)
            data.firstSector = readUint4(file, off+9)
            data.filename = trim(readChars(file, off+13, 10))
            data.ext = trim(readChars(file, off+23, 3))
            data.perms = readUint2(file, 26)
            data.uid = readUint2(file, 28)
            data.gid = readUint2(file, 30)
            entries[#entries+1] = data
        end
        if data.attributes == 0 then break end
    end
    return entries
end

api.createInitial = function(device)
    local drive,e = k.filesystem.open(device)
    if not drive then return false, e end
    local d, partitionNr = device:match("/dev/(hd[%d]+)p([%d]+)$")
    local current = drives.getPartitionByNumber(drives.getAddrOf(d), tonumber(partitionNr))
    if not current then
        return false, "Partition Not Found!"
    end
    local sectors = (ioctl(drive, "getCapacity") / ioctl(drive, "getSectorSize"))

    writeUint4(drive, 1, sectors)
    writeUint4(drive, 21, math.random(0x10000000, 0xFFFFFFF0))
    writeUint4(drive, 25, current.firstSector + 1)

    -- Root directory
    local currentTime = tonumber(string.format("%.0f", k.time()/1000))
    writeUint4(drive, 512+1, 10)
    writeUint4(drive, 512 + 5, currentTime)
    writeUint (drive, 512 + 9, 0)

    writeUint4(drive, 5120+1, 0xFFFFFFFF)
    writeUint4(drive, 5120 + 5, currentTime)
    writeUint (drive, 5120 + 9, 0)
    k.filesystem.close(drive)
    return true
end

api.findEntry = function(device, filename, sectors, isDir)
    checkArg(1, device, "string")
    checkArg(2, filename, "string")
    checkArg(3, sectors, "table")
    checkArg(4, isDir, "boolean", "nil")
    local entries = api.getEntries(device, sectors)

    local fext 
    local filen
    local lastDotPos = (filename:reverse()):find("%.")
    if lastDotPos then
        fext = filename:sub(1 - lastDotPos):sub(1, 3)
        filen = filename:sub(1, lastDotPos + 1)
    else
        fext = ""
        filen = filename:sub(1, 10)
    end
    for key, entry in ipairs(entries) do
        -- k.write(dump{trim(entry.filename), filen, entry.ext, fext, lastDotPos})
        if trim(entry.filename) == filen and entry.ext == fext then
            return entry
        end
    end
    return nil, "File or Directory not found"
end


api.findEntryDeep = function(device, parent, filename, isDir)
    checkArg(1, device, "string")
    checkArg(2, parent, "string")
    checkArg(3, filename, "string")
    checkArg(4, isDir, "boolean", "nil")
    if parent:sub(1,1) ~= "/" then
        return nil, "Only Absolute Paths are allowed"
    end
    local parts = split(parent, "/")
    local data, e = api.read(device)
    
    local sectors = data.rootDirSectors
    for i = 1, #parts do
        local currentEntry, e = api.findEntry(device, parts[i], sectors, true)
        if not currentEntry then
            return nil, e
        end
        if not currentEntry or (currentEntry.attributes & (1<< 4)) == 0 then
            return nil, string.format("%s is not a directory A", parts[i])
        end 
        sectors = api.getSectors(device, currentEntry.firstSector)
    end
    local entry, e = api.findEntry(device, filename, sectors, false)
    if not entry or ((entry.attributes & (1<< 4)) == 0 and isDir) then
        return nil, string.format("%s is not a directory: %s", filename, dump(isDir))
    end
    if (entry.attributes & (1<< 4)) == 0 and not isDir then
        local lastDotPos = (filename:reverse()):find("%.")
        local fext = filename:sub(1 - lastDotPos):sub(1, 3)
        if entry.ext ~= fext then
            return nil, "Same entry with two extensions!" 
        end
    end
    return entry -- FIXME: check if there is a file with same name but diffrent ext
end

api.getContent = function(device, path)
    if path:sub(1,1) ~= "/" then
        return nil, "Only Absolute Paths are allowed"
    end
    local parts = split(path, "/")
    local name = parts[#parts]
    parts[#parts] = nil
    local entry,e = api.findEntryDeep(device, "/" .. table.concat(parts, "/"), name, false)
    if not entry then return nil, e end
    local sectors = api.getSectors(device, entry.firstSector)
    -- k.write(dump(sectors))
    local file, e = open(device)
    if not file then return nil, e end
    local content = ""
    for i = 1, #sectors do
        local data = ioctl(file, "readSector", sectors[i] + 1)
        local fullFNCount = 0
        if i == 1 then
            fullFNCount = string.unpack("B", string.pack("B", string.byte(data:sub(9, 9))))
            local fullFN = data:sub(10, 10+fullFNCount)
            if fullFN ~= name and fullFNCount > 0 then
                return nil, "Multiple files exists for same 10.3 filename!"
            end
        end
        content = content .. data:sub(10+fullFNCount)
    end

    return trim(content)
end

api.createFileEntry = function(device, path, filename, opts)
    checkArg(2, path, "string")
    checkArg(3, filename, "string")
    checkArg(4, opts, "table")
    local currentTime = tonumber(string.format("%.0f", k.time()/1000))

    local attributes = (opts.attributes or 0) & 31 | 1 << 5
    local created = opts.created or currentTime
    local lastAccess = opts.lastAccess or currentTime
    local fileSize = opts.fileSize or 0
    local firstSector = opts.firstSector
    assert(firstSector, "Missing option `firstSector` in lfs.createFile")
    local drive, e = open(device)
    if not drive then return nil, e end
    local sectors = (ioctl(drive, "getCapacity") / ioctl(drive, "getSectorSize"))
    assert(firstSector >= 2 and firstSector <= sectors - 1, "Bad value for option `firstSector` in lfs.createFile")
    local filen, fext
    if attributes & 1<<4 == 0 then
        local lastDotPos = (filename:reverse()):find("%.")
        fext = filename:sub(1 - lastDotPos):sub(1, 3)
        filen = filename:sub(1, lastDotPos + 1)
    else
        fext = ""
        filen = filename:sub(1, 10)
    end
        local perm = (opts.perm or (1<<9)-1) & (1<<9)-1
        local uid = opts.uid or 0
        local gid = opts.gid or 0
    
    local entryStart, e = api.findFreeEntry(device, path)
    if entryStart < 0 then
        return nil, "Not Enough Space Left!"
    end

    writeUint (drive, entryStart, attributes)
    writeUint4(drive, entryStart + 1, lastAccess)
    writeUint4(drive, entryStart + 5, fileSize)
    writeUint4(drive, entryStart + 9, firstSector)
    writeChars(drive, entryStart + 13, filen)
    writeChars(drive, entryStart + 23, fext)
    writeUint2(drive, entryStart + 26, perm)
    writeUint2(drive, entryStart + 28, uid)
    writeUint2(drive, entryStart + 30, gid)
    return true
end

api.findFreeSector = function(device)
    local file, e = open(device)
    if not file then return nil, e end
    local data = api.read(device)
    local sectorSize = ioctl(file, "getSectorSize")
    for i = 1 + data.rootDirOff, data.sectorCount do
        local next = readUint4(file, i * sectorSize + 1)
        -- k.write(dump(next))
        if next == 0 then
            return i
        end
        -- break
    end
    return -1, "Filesystem Full"
end

api.allocateFreeSector = function(device, path, isDir)
    local parts = split(path, "/")
    local name = parts[#parts]
    parts[#parts] = nil
    local entry,e = api.findEntryDeep(device, "/" .. table.concat(parts, "/"), name, isDir)
    if not entry then return nil, e end
    -- k.write(dump(entry))
    local sectors = api.getSectors(device, entry.firstSector)
    local free, e = api.findFreeSector(device)
    if free < 0 then return nil, e end
    k.write(dump(free))
    local file, e = open(device)
    if not file then return nil, e end
    local sectorSize = ioctl(file, "getSectorSize")
    writeUint4(file, free*sectorSize + 1, 0xFFFFFFFF) -- last sector in file
    writeUint4(file, free*sectorSize + 5, tonumber(string.format("%.0f", k.time()/1000))) -- currentTime
    writeUint(file, free*sectorSize + 9, 0)
    writeUint4(file, sectors[#sectors]*sectorSize + 1, free)
    return api.getSectors(device, entry.firstSector)
end

api.findFreeEntry = function(device, path)
    local parts = split(path, "/")
    local name = parts[#parts]
    parts[#parts] = nil
    local sectors
    if path ~= "/" then
        local entry = api.findEntryDeep(device, "/" .. table.concat(parts, "/"), name, true)
        sectors = api.getSectors(device, entry.firstSector)
    else
        local data = api.read(device)
        sectors = data.rootDirSectors
    end
    local file, e = open(device)
    if not file then return nil, e end
    for i=1, #sectors do
        local data = ioctl(file, "readSector", sectors[i]+1)
        local fullFNCount = string.unpack("B", string.pack("B", string.byte(data:sub(9, 9))))
        assert(i == 1 or fullFNCount == 0, "Invalid fullFNCount Value!")
        if i == 1 then
            local fullFN = data:sub(10, 10+fullFNCount)
            if fullFN ~= name and fullFNCount > 0 then
                return nil, "Multiple files exists for same 10.3 filename!"
            end
        end
        local sectorSize = ioctl(file, "getSectorSize")
        local idx = 10 + fullFNCount
        -- k.write(dump(data))
        while (idx + 32) <= sectorSize do
            local attr = readUint(file, idx + sectors[i] * sectorSize)
            -- k.write(dump(attr))
            if attr == 0 then
                return idx + sectors[i] * sectorSize
            end
            idx = idx + 32
        end
    end
    return -1, "No Space Left!"
end

api.writeFile = function(device, path, content)
    local parts = split(path, "/")
    local name = parts[#parts]
    parts[#parts] = nil
    local entry,e = api.findEntryDeep(device, "/" .. table.concat(parts, "/"), name, isDir)
    if not entry then return nil, e end
    if (entry.attributes & (1 << 4)) ~= 0 then return nil, "Cannot write Filedata to Directory" end
    -- k.write(dump(entry))
    local sectors = api.getSectors(device, entry.firstSector)
    local maxFileSize = 0

    local file, e = open(device)
    if not file then return nil, e end
    local sectorSize = ioctl(file, "getSectorSize")
    local maxPerSector = {}

    for idx, sec in ipairs(sectors) do
        local lfnCount = readUint(file, sec*sectorSize + 9)
        if idx > 1 and lfnCount ~= 0 then
            return nil, string.format("Invalid LongFileName for sector %.0f (File: %s, Sector-Offset: %.0f)", sec, path, idx)
        end
        maxFileSize = maxFileSize + (512 - 9 - lfnCount)
        maxPerSector[sec] = (512 - 9 - lfnCount)
    end
    if content:len() > maxFileSize - 3 then assert(false, "More Allocation not supported!") end
    for sec, mps in pairs(maxPerSector) do
        local off = 512 - mps + 1
        local data = string.rep("\0", mps)
        writeChars(file, sec*sectorSize+off, data)
        writeChars(file, sec*sectorSize+off, content:sub(1, mps - 3))
        k.write(dump(content))
        content = content:sub(mps - 3)
        k.write(dump(content:sub(1, mps - 3)))
    end
    k.filesystem.close(file)
    -- k.write(dump{maxFileSize, content:len()})
    assert(content:len() == 0, string.format("content:len(): %.0f", content:len()))
    return true
end

api.list = function(device, path)
    local parts = split(path, "/")
    local name = parts[#parts]
    parts[#parts] = nil
    local sectors
    if path ~= "/" then
        local entry = api.findEntryDeep(device, "/" .. table.concat(parts, "/"), name, true)
        if not entry then return nil, "File Or Directory does not exists" end
        if (entry.attributes & (1 << 4)) == 0 then return nil, "Cannot list File" end
        sectors = api.getSectors(device, entry.firstSector)
    else
        local data = api.read(device)
        sectors = data.rootDirSectors
    end
    -- k.write(dump(entry))
    local file, e = open(device)
    if not file then return nil, e end
    local entries = api.getEntries(device, sectors)
    
    local files = {}
    local sectorSize = ioctl(file, "getSectorSize")
    for _, entry in ipairs(entries) do
        local fullFNCount = readUint(file, entry.firstSector * sectorSize + 9)
        assert(fullFNCount == 0, "LFN Entry is unsupported!")
        
        -- local fullFN = data:sub(10, 10+fullFNCount)
        -- if fullFN ~= name and fullFNCount > 0 then
        --     return nil, "Multiple files exists for same 10.3 filename!"
        -- end
        local filename = entry.filename
        if (entry.attributes & (1 << 4)) == 0 then 
            filename = filename.. "." .. entry.ext
        end
        files[#files+1] = filename
    end
    return files
end


return api
