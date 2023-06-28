do
    if computer.getArchitecture() ~= "Lua 5.3" then
        error("Failed to Boot: OS requires Lua 5.3")
        _G.computer.shutdown()
    end

    function trim(s)
        if s:sub(-1, -1) ~= " " then return s end
        repeat
            s = s:sub(1, -2)
        until s:sub(-1, -1) ~= " "
        return s
    end

    local screen = component.list("screen", true)()
    local gpu = screen and component.list("gpu", true)()
    local s = {x = 1, y = 1}
    do
        if gpu then 
            gpu = component.proxy(gpu)
        
            if gpu then
                if not gpu.getScreen() then
                    gpu.bind(screen)
                end
                local w, h = gpu.getResolution()
                s.w = w
                s.h = h
                gpu.setResolution(w, h)
                gpu.setForeground(0xFFFFFF)
                gpu.setBackground(0x000000)
                gpu.fill(1, 1, w, h, " ")
            end
        end
    end

    local function print(msg)
        if gpu then
            local sw, sh = gpu.getResolution() 
    
            gpu.set(s.x, s.y, msg)
            if s.y == sh then
                gpu.copy(1, 2, sw, sh - 1, 0, -1)
                gpu.fill(1, sh, sw, 1, " ")
            else
                s.y = s.y + 1
            end
            s.x = 1
        end
    end
    

    _G.lib = {}
    local addr, invoke = computer.getBootAddress(), component.invoke
    
    local vfs = ""

    local function readUint(pos)
        return string.unpack("B", vfs:sub(pos, pos))
    end

    local function readUint2(pos)
        local value = readUint(pos)
        value = value | readUint(pos + 1) << 8 
        return value
    end

    local function readUint4(pos)
        local value = readUint(pos)
        value = value | readUint(pos + 1) << 8
        value = value | readUint(pos + 2) << 16
        value = value | readUint(pos + 3) << 24
        return value
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

    local function dump(o)
        if type(o) == 'table' then
            local s = '{ '
            for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
            end
            return s .. '} '
        else
            if type(o) == "string" then return string.format("'%s'", tostring(o)) end
            return tostring(o)
        end
    end

    local function initvfs(file)
        local handle = assert(invoke(addr, "open", file))
       
        repeat
            local data = invoke(addr, "read", handle, math.huge)
            vfs = vfs .. (data or "")
        until not data
        invoke(addr, "close", handle)

        if readUint2(511) ~= 0x55aa then
            error("Verification Failed: Kernel is not loadable")
        end

        if readUint2(1) ~= 512 then
            error("Verification Failed: Index 0 (length 2) is not 512")
        end
        local tsc = readUint4(5)
        if tsc ~= (vfs:len()) / 512 then
            error(string.format("Verification Failed: Total sector count is invalid! Expected %.1f, got %.1f", (vfs:len()) / 512, tsc))
        elseif vfs:sub(9, 13) ~= "LPT0 " then
            error("Verification Failed: Missing String 'LPT0'")
        end
        
        local part = {}
        do
            part.attributes = readUint(439)
            if part.attributes & 1 == 0 then
                error("Verification Failed: First Partition needs to be a system Partition")
            end
            part.firstSector = readUint4(440)
            if part.firstSector ~= 3 then
                error("Verification Failed: First Sector must be 3 is " .. tostring(part.firstSector))
            end
            part.number = readUint(444)
            if part.number ~= 1 then
                error("Verification Failed: number must be 1 is " .. tostring(part.number))
            end
            part.name = vfs:sub(445, 449)
            if part.name ~= "boot " then
                error(string.format("Verification Failed: Name must be 'boot ' is: '%s' %.0f", part.name, part.name:len()))
            end
            part.type = readUint(450)
            if part.type ~= 1 then
                error("Verification Failed: number must be 1 is " .. tostring(part.number))
            end
            part.size = readUint(451)
            if part.size < 16 then
                error("Verification Failed: Invalid Size")
            end
        end

        -- Drive Head Verification success
        pos = part.firstSector * 512 + 1
        local bootdata = {}
        do
            bootdata.sectorCount = readUint4(pos)
            if bootdata.sectorCount < 16 and bootdata.sectorCount < tsc - 3 then
                error("Verification Failed: LFS SectorCount needs to be more or equal to 16")
            end
            pos = pos + 20
            bootdata.signature = readUint4(pos)
            pos = pos + 4
            bootdata.rootDirStart = readUint4(pos)
            if bootdata.rootDirStart - part.firstSector < 1 then
                error("Verification Failed: LFS RootDirStart is invalid")
            end
            pos = pos + 4
            bootdata.label = vfs:sub(pos, pos+16)
        end
        local function readDir(parentPath, posStart, recursive)
            local files = {}
            pos = (posStart or bootdata.rootDirStart) * 512 + 1
            local i = 0
            while true do
                i = i + 1
                local next = readUint4(pos)
                
                pos = pos + 8
                local lfn = readUint(pos)
                -- if pos >= 0x2600 and pos <= 0x2800 then error(lfn) end 
                if lfn ~= 0 then
                    print(string.format("Read Failed: Invalid LFN Count for Directory %.0f %.0f", pos, lfn))
                    while true do computer.pullSignal(0.1) end
                end
                pos = pos + 1
                -- error(dump({pos, pos+32, (bootdata.rootDirStart + i) * 512}))
                while (pos + 32) <= ((posStart or bootdata.rootDirStart) + i) * 512 do
                    local attr = readUint(pos)
                    if attr & 1 << 5 == 0 then
                        pos = pos + 32
                        goto loopend
                    end
                    
                    pos = pos + 1
                    local entry = {}
                    entry.attr = attr
                    entry.lastAccess = readUint4(pos)
                    pos = pos + 4
                    entry.size = readUint4(pos)
                    pos = pos + 4
                    entry.firstSector = readUint4(pos)
                    pos = pos + 4
                    entry.filename = vfs:sub(pos, pos+9)
                    pos = pos + 10
                    entry.ext = vfs:sub(pos, pos+2)
                    pos = pos + 3
                    entry.perms = readUint2(pos)
                    pos = pos + 2
                    entry.uid = readUint2(pos)
                    pos = pos + 2
                    entry.gid = readUint2(pos)
                    pos = pos + 2
                    
                    
                    if entry.attr & 1 << 4 ~= 0 and recursive == true then
                        for k, v in pairs(readDir(parentPath .. entry.filename, entry.firstSector + part.firstSector)) do
                            local p = parentPath .. "/" .. trim(entry.filename) .. "/" .. trim(v.filename) .. "." .. trim(v.ext)
                            files[p] = v
                        end
                    else
                        files[parentPath .. "/" .. trim(entry.filename) .. "." .. trim(entry.ext)] = entry
                    end

                    local backup_pos = pos
                    pos = (entry.firstSector + part.firstSector) * 512 + 9
                    local lfn = readUint(pos)
                    local lfnName = ""
                    if lfn >= 1 and i == 1 then
                        lfnName = vfs:sub(pos+1, pos+lfn)
                        local f = lfnName:gmatch("([^.]+)")
                        entry.filename = entry.filename .. f()
                        entry.ext = f()
                    elseif lfn >= 1 and i ~= 1 then
                        error(string.format("Invalid LFN for Sector! %s %.0f %.0f %.0f", entry.filename, pos, i, lfn))
                    end
                    pos = backup_pos



                    ::loopend::
                end
                pos = ((posStart or bootdata.rootDirStart) + i) * 512 + 1
                -- error("")
                if next == 0xFFFFFFFF then
                    break
                end
            end
            return files
        end
        local files = readDir("", nil, true)
        local files_ = {}
        local fileslist = {}
        for k, v in pairs(files) do
            table.insert(fileslist, trim(k))
            files_[trim(k)] = v
        end
        files = files_
        -- error(dump(fileslist))
        _G.readfileK = function(path)
            if path:sub(1,1) == "/" then path = path:sub(2) end
            
            local parts = {}
            local p = path:gmatch("([^/]+)")
            repeat
                local d = p()
                if d then
                    parts[#parts+1] = d
                end
            until not d
            local fname = parts[#parts]
            parts[#parts] = nil
            local parent = table.concat(parts, "/")

            local filen = fname:gmatch("([^.]+)")
            local p = ""
            if parent:len() ~= 0 then p = "/" .. parent end
            local v = files[p .. "/" .. filen() .. "." .. filen()]
            if v == nil then
                for k, _v in pairs(files) do
                    print(dump{k, v})
                end
                local filen = fname:gmatch("([^.]+)")
                -- local v = files[parent .. "/" .. filen() .. "." .. filen()]
                -- while true do computer.pullSignal(.1) end
                error(dump(p .. "/" .. filen() .. "." .. filen()))
                return nil, "File not Found!"
            end
            
            local pos = (v.firstSector + part.firstSector) * 512 + 1
            local content = ""
            local remaining = v.size
            local i = 0
            while true do
                local next = readUint4(pos)
                pos = pos + 8
                local lfn = readUint(pos)
                if lfn ~= 0 and i ~= 0 then
                    error("!")
                end
                pos = pos + 1
                local block = math.ceil(pos / 512) * 512
                local data = ""
                
                if (block - pos - lfn) <= remaining then
                    data = vfs:sub(pos+lfn, block)
                    remaining = remaining - (block - pos - lfn)
                else
                    data = vfs:sub(pos+lfn, pos+remaining+lfn)
                end
                content = content .. data
                -- if data:len() ~= v.size and remaining <= 0 then
                -- end
                if next == 0xFFFFFFFF then
                    return content:sub(1, v.size)
                end
                i = i + 1
                pos = (next + part.firstSector) * 512 + 1
            end
            return content
        end

        _G.loadfileK = function(path)
            local content, e = readfileK(path)
            
            if not content then return nil, e .. ": " .. path end
            if content:len() == 0 then
                return nil, "Cannot Read File!"
            end
            return load(content, "=" .. path, "bt", _G)
        end

        _G.getFiles = function() return files end

    end
    initvfs("/System/kernel")

    local kernel, e = loadfileK("/kernel.lua")
    if kernel == nil then
        error("Kernel could not be loaded: " .. e)
    end
    _G.lib.loadfile = function(path)
        if path:sub(1, 14) == "/System/Kernel" then
            return loadfileK(path:sub(15))
        else
            -- error(dump{path, path:sub(1, 15)})
            local handle = assert(invoke(addr, "open", path))
            local buffer = ""
            repeat
                local data = invoke(addr, "read", handle, math.huge)
                buffer = buffer .. (data or "")
            until not data
            invoke(addr, "close", handle)
            return load(buffer, "=" .. path, "bt", _G)
        end
    end
    _G.listfiles = function(path)
        if path:sub(1, 14) == "/System/Kernel" then
            path = path:sub(15)
            local f = {}
            for _k, _v in pairs(getFiles()) do
                if _k:sub(1, path:len()) == path then f[#f+1] = trim(_k:sub(path:len() + 2)) end
            end
            return f
        else
            return invoke(addr, "list", path)
        end
    end
    kernel()
    
end