local api = {}

mounts = {}

local function getAddrAndPath(_path)
    if _path:sub(1, 1) ~= "/" then _path = "/" .. _path end
    if mounts[_path] ~= nil then return mounts[_path], "/" end 
    local parts = {}
    
    _path = string.sub(_path, 2, -1)
    for part in string.gmatch(_path, "([^/]+)") do
      table.insert(parts, part)
    end
    
    local i = #parts
    
    repeat
        local joined = ""
        for j=1,i do 
            joined = joined .."/" .. parts[j]   
        end

        if mounts[joined] ~= nil then
            local resPath = ""
            for j=i+1,#parts do resPath = resPath .. "/"..parts[j] end
            return mounts[joined], resPath
        end
        i = i - 1
    until i == 0
    return mounts["/"], _path
  end

-------------------------------------------

api.mount = function(addr, tPath)
    checkArg(1, addr, "string")
    checkArg(2, tPath, "string")

    if not mounts["/"] then
        if tPath ~= "/" then
            return nil, "Please Mount RootPath first"
        end
    end

    mounts[tPath] = addr
end

api.isMount = function(point)
    checkArg(1, point, "string")
    return mounts[point] ~= nil
end

api.umount = function(point)
    checkArg(1, point, "string")
    
    if not isMount(point) then
        return false
    end
    mounts[point] = nil
    return true
end

api.getAddress = function (path)
    checkArg(1, path, "string")

    local addr, _ = getAddrAndPath(path)
    return addr
end

api.isFile = function(path)
    checkArg(1, path, "string")

    local addr, resPath = getAddrAndPath(path)
    if addr == nil then
        --error(path .. " " .. dump(mounts))
        error(debug.traceback())
    end
    return component.invoke(addr, "exists", resPath) and not component.invoke(addr, "isDirectory", resPath)
end

api.isDirectory = function(path)
    checkArg(1, path, "string")
    
    local addr, resPath = getAddrAndPath(path)
    return component.invoke(addr, "exists", resPath) and component.invoke(addr, "isDirectory", resPath)
end

api.open = function(path, mode)
    checkArg(1, path, "string")
    checkArg(2, mode, "string")

    local addr, resPath = getAddrAndPath(path)
    if addr == nil then
        error("File Not Existing: " .. path)
    end
    if not api.isFile(path) then
        return nil, "Cannot Open file: File not existing"
    end
    local res = {}
    do
        local handle = component.invoke(addr, "open", resPath, mode)
        
        
        function res:read(size)
            checkArg(1, size, "number")
            return component.invoke(addr, "read", handle, size)
        end

        function res:write(buf)
            checkArg(1, buf, "string")
            coroutine.yield()
            return component.invoke(addr, "write", handle, buf)
        end

        function res:seek(_whence, _offset)
            checkArg(1, _whence, "string")
            checkArg(2, _offset, "number")
            return component.invoke(addr, "seek", handle, _whence, _offset)
        end

        function res:close()
            return component.invoke(addr, "close", handle)
        end
    end
    return res
end

api.listDir = function(dir)
    local addr, resPath = getAddrAndPath(dir)
    return component.invoke(addr, "list", resPath)
end

api.getFilesize = function(file)
    local addr, resPath = getAddrAndPath(file)
    if not api.isDirectory(resPath) then
        return component.invoke(addr, "size", resPath)
    end
    return 0
end

api.getLastEdit = function(path)
    local addr, resPath = getAddrAndPath(path)
    return component.invoke(addr, "lastModified", resPath)
end
return api