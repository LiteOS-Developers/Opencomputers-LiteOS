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

local function sizeR(bytes)
    local t = {"", "ki", "Mi", "Gi"}
    local i = 1
    repeat 
        bytes = bytes / 1024
        i = i + 1
        coroutine.yield()
    until bytes < 1024
    return string.format("%.1f%sB", bytes, t[i])
end

local function size(convert, bytes)
    if not convert then
        return trunc(string.format("%.0f", bytes), 8)
    end
    return trunc(sizeR(bytes), 8)
end


return {
    main = function(args)
        local drives = require("system.Drives")
        if not drives then
            print("fdisk: Requires elevated Rights")
            return -1
        end
        if #args < 2 then
            print("fdisk: Not enough Arguments\nRun 'fdisk -h'")
            return -1
        end
        if args[2] == "-h" or args[2] == "--help" then
            print([[
Usage:
    fdisk [options]
    fdisk [disk]
            
Options:
    --list, -l      List Disks
    --human, -h     Convert sizes
            ]])
        elseif table.contains(args, "-l") or table.contains(args, "--list") then
            local humanize = table.contains(args, "-h") or table.contains(args, "--human")
            local devices = drives.list()
            print("Device     Size     Sectors Sector-Size")
            for idx, addr in pairs(devices) do
                local data = drives.read(addr)
                print(string.format("%s   %s %s %s", 
                    trunc(string.sub(drives.getNameOf(addr), 1, 8), 8),
                    size(humanize, data.total_sector_count * data.sector_size), 
                    trunc(string.format("%.0f", data.total_sector_count), 7),
                    trunc(string.format("%.0f", data.sector_size), 7)
                ))
                for idx, part in pairs(data.partitions) do
                    print(string.format("  %s %s %s %s",
                        trunc(string.sub(drives.getNameOf(addr) .. "p" .. string.format("%.0f", part.partition_number), 1, 8), 8),
                        size(humanize, part.size * data.sector_size),
                        trunc(string.format("%.0f", part.size),7),
                        trunc(string.format("%.0f", data.sector_size), 7)    
                    ))
                end
            end
            coroutine.yield()
        else
            local shell = require("Shell").connect("tty0")
            local file = shell:resolvePath(args[2])
            if filesystem.isFile(file) and file:sub(1, 5) == "/dev/" then
                local devices = drives.list()
                local name = file:sub(6)
                for idx, addr in pairs(devices) do
                    if drives.getNameOf(addr) == name then
                        local data = drives.read(addr)
                        print(string.format([[
Modifying: %s
PartitionTable: %s
Size: %s
]],
                            name, data.lpt, sizeR(data.total_sector_count * data.sector_size)
                        ))
                        while true do
                            data = drives.read(addr)
                            local cmd = shell:read(name .. "> ")
                            if cmd == "q" then
                                return 0
                            elseif cmd == "h" then
                                print([[
Help Overview:
    h   prints help message
    p   print partition table
    t   Create new Empty LPT Partition Table
    n   Create new Partition
    f   Lists Free Space
]]
                                )
                            elseif cmd == "p" then
                                print("Device   Start  End    Sectors  Size")
                                for i, part in pairs(data.partitions) do
                                    print(string.format("%s %s %s %s %s",
                                        trunc(string.sub(drives.getNameOf(addr) .. "p" .. string.format("%.0f", part.partition_number), 1, 8), 8),
                                        trunc(string.format("%.0f", part.firstSector), 6),
                                        trunc(string.format("%.0f", part.firstSector + part.size), 6),
                                        trunc(string.format("%.0f", part.size), 8),
                                        size(true, part.size*data.sector_size)
                                    ))
                                end
                            elseif cmd == "f" then
                                local free = drives.listFreeSpace(addr)
                                print("Start    Size")
                                for idx, f in pairs(free) do
                                    -- print(dump(f))
                                    print(string.format("%s %s",
                                        trunc(string.format("%.0f", f.begin), 8),
                                        trunc(string.format("%.0f", f.count), 8)
                                    ))
                                end
                            elseif cmd == "t" then
                                local answer = shell:read(
                                    "Are you sure you want to create a new LPT Partition Table? This will erase all Data [N/y] ")
                                if answer == "y" or answer == "Y" then
                                    drives.createLPT(addr)
                                    print("Written LPT")
                                else
                                    print("Aborted!")
                                end
                            elseif cmd == "n" then
                                local name = shell:read("Name (5 Chars) > ")
                                local size = tonumber(shell:read("Size> "))
                                local answer = shell:read(
                                    "Are you sure you want to create that Partition? [N/y] ")
                                if answer == "y" or answer == "Y" then
                                    -- print(addr)
                                    local next, e = drives.getNextFreeSector(addr, size)
                                    if not next then 
                                        print(e)
                                        return -1
                                    end
                                    local success, e = drives.createPartition(addr, name, size, 0, next, 1)
                                    if success then
                                        print("Parition Created")
                                    else
                                        print(e)
                                    end
                                else
                                    print("Aborted!")
                                end
                            end
                        end
                    end
                end
                print("fdisk: No Device matching that name found!")
            else
                print("fdisk: Expected Device file")
            end
        end
        return 0
    end
}