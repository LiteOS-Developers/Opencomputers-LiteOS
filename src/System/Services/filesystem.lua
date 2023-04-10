local api = {}

mounts = {}
api.handles = {}

local function getAddrAndPath(_path)
    if _path:sub(1, 1) ~= "/" then _path = "/" .. _path end
    if mounts[_path] ~= nil then return mounts[_path].addr, "/" end 
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
            return mounts[joined].addr, resPath
        end
        i = i - 1
    until i == 0
    return mounts["/"].addr, _path
end

local function parts(p)
    if p:sub(1, 1) == "/" then p = p:sub(2, -1) end
    local parts = {}
    for part in string.gmatch(p, "([^/]+)") do
        table.insert(parts, part)
    end
    return parts
end

-------------------------------------------

api.mount = function(addr, tPath, opts)
    checkArg(1, addr, "string")
    checkArg(2, tPath, "string")
    checkArg(3, opts, "table", "nil")

    if not mounts["/"] then
        if tPath ~= "/" then
            return nil, "Please Mount RootPath first"
        end
    end

    mounts[tPath] = {addr=addr,opts=opts}
end

api.isMount = function(point)
    checkArg(1, point, "string")
    return mounts[point] ~= nil
end

api.umount = function(point)
    checkArg(1, point, "string")
    
    if not api.isMount(point) then
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
        -- error(path .. " " .. dump(mounts))
        error(debug.traceback())
    end
    return component.invoke(addr, "exists", resPath) and not component.invoke(addr, "isDirectory", resPath)
end

api.isDirectory = function(path)
    checkArg(1, path, "string")
    
    local addr, resPath = getAddrAndPath(path)
    return (component.invoke(addr, "exists", resPath) and component.invoke(addr, "isDirectory", resPath)) or api.isMount(path)
end

api.read = function(handle, size)
    checkArg(1, handle, "number")
    checkArg(2, size, "number")
    return component.invoke(api.handles[handle].addr, "read", api.handles[handle].handle, size)
end

api.write = function(handle, buf)
    checkArg(1, handle, "number")
    checkArg(2, buf, "string")
    return component.invoke(api.handles[handle].addr, "write", api.handles[handle].handle, buf)
end
api.seek = function(handle, _whence, offset)
    checkArg(1, handle, "number")
    checkArg(2, _whence, "number")
    checkArg(3, offset, "number")
    return component.invoke(api.handles[handle].addr, "seek", api.handles[handle].handle, _whence, offset)
end
api.close = function(handle)
    checkArg(1, handle, "number")
    api.handles[handle].closed = true
    component.invoke(api.handles[handle].addr, "close", api.handles[handle].handle)
end

api.getRealHandle = function(handle)
    checkArg(1, handle, "number")
    return api.handles[handle].handle
end
api.open = function(path, m)
    checkArg(1, path, "string")
    checkArg(2, m, "string", "nil")
    m = m or "r"
    local mode = {}
    
    local addr, resPath = getAddrAndPath(path)
    if addr == nil then
        return nil, "No such file or directory: " .. path
    end
    for i = 1, unicode.len(m) do
        mode[unicode.sub(m, i, i)] = true
    end
    if not api.isFile(path) and mode.w ~= true then
        -- error(dump(addr))
        return nil, "Cannot open file: File not existing"
    end
    
    local handle = component.invoke(addr, "open", resPath, m)
    table.insert(api.handles, {handle = handle, addr = addr, closed=false, mode = mode})
    assert(api.ensureOpen(#api.handles), "Handle " .. tostring(#api.handles) .. " (File: " .. path .. ") wasn't opened successfully")
    return #api.handles, nil
end

api.ensureOpen = function(handle)
    checkArg(1, handle, "number")
    if api.handles[handle] == nil then
        k.panic("ensureOpen on invalid Handle: " .. tonumber(handle))
    end
    if component.hasMethod(api.handles[handle].addr, "ensureOpen") then
        return component.invoke(api.handles[handle].addr, "ensureOpen", api.handles[handle].handle)
    end
    return not api.handles[handle].closed
end

api.listDir = function(dir)
    local addr, resPath = getAddrAndPath(dir)
    local listed = component.invoke(addr, "list", resPath)
    local files = {}
    for _, f in ipairs(listed) do
        if f:sub(-5, -1) ~= ".attr" then table.insert(files, f) end
        -- k.write(f)
    end
    for path, o in pairs(mounts) do
        if o.addr ~= addr then
            local parts = parts(path)
            table.remove(parts, #parts)
            if "/" .. table.concat(parts, "/") == dir then
                if path:sub(1, 1) == "/" then path = path:sub(2, -1) end
                if path:sub(-1, -1) ~= "/" then path = path .. "/" end
                table.insert(files, path)
            end
        end
    end
    return files
end

api.remove = function(path)
    checkArg(1, path, "string")
    if path:sub(-5) == ".attr" then return false end
    local addr, resPath = getAddrAndPath(path)
    return component.invoke(addr, "remove", resPath)
end

api.getAttrs = function(path)
    checkArg(1, path, "string")
    local addr, resPath = getAddrAndPath(path)
    local handle = component.invoke(addr, "open", resPath .. ".attr", "r")
    local data = ""
    local buf
    repeat
        buf = component.invoke(addr, "read", handle, math.huge)
        data = data .. (buf or "")
    until not buf
    component.invoke(addr, "close", handle)

    local attrs = string.gmatch(data, "[^\n]+")
    local parsed = {}
    local n, kv, key, value
    while true do
        n = attrs()
        if not n then break end
        kv = string.gmatch(n, "[^:]+")
        key = kv()
        value = (kv() or ""):gsub("\r", "")
        if value:sub(1,1) == " " then value = value:sub(2) end
        parsed[key] = value
    end
    -- k.write(resPath..  ": " .. dump(parsed))

    return parsed
end

api.getFilesize = function(file)
    local addr, resPath = getAddrAndPath(file)
    if not api.isDirectory(resPath) then
        return component.invoke(addr, "size", resPath)
    end
    return 0
end

api.getLastEdit = function(path)
    path = "/" .. table.concat(parts(path), "/")
    -- k.write(path)
    if mounts[path] ~= nil then 
        return 0
    end
    local addr, resPath = getAddrAndPath(path)
    return component.invoke(addr, "lastModified", resPath)
end
return api