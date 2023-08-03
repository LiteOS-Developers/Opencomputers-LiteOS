--#skip 13
--[[
    Copyright (C) 2023 thegame4craft

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

--#define DRV_ROOTFS
k.printk(k.L_INFO, "drivers/rootfs")
k.rootfs = {
    mounts = {}
}

local function getAddrAndPath(_path)
    if _path:sub(1, 1) ~= "/" then _path = "/" .. _path end
    if k.rootfs.mounts[_path] ~= nil then return k.rootfs.mounts[_path].addr, "/" end 
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

        if k.rootfs.mounts[joined] ~= nil then
            local resPath = ""
            for j=i+1,#parts do resPath = resPath .. "/"..parts[j] end
            return k.rootfs.mounts[joined].addr, resPath
        end
        i = i - 1
    until i == 0
    return k.rootfs.mounts["/"].addr, _path
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

function k.rootfs.mount(addr, tPath, opts)
    checkArg(1, addr, "string")
    checkArg(2, tPath, "string")
    checkArg(3, opts, "table", "nil")

    if not k.rootfs.mounts["/"] then
        if tPath ~= "/" then
            return nil, "Please Mount rootfs first"
        end
    end

    k.rootfs.mounts[tPath] = {addr=addr,opts=opts}
end

function k.rootfs.isMount (point)
    checkArg(1, point, "string")
    return k.rootfs.mounts[point] ~= nil
end

function k.rootfs.umount(point)
    checkArg(1, point, "string")
    
    if not api.isMount(point) then
        return false
    end
    k.rootfs.mounts[point] = nil
    return true
end

function k.rootfs.getAddress(path)
    checkArg(1, path, "string")

    local addr, _ = getAddrAndPath(path)
    return addr
end

function k.rootfs.spaceUsed(path)
    checkArg(1, path, "string")
    local addr, _ = getAddrAndPath(path)
    return k.component.invoke(addr, "spaceUsed")
end

function k.rootfs.open(path)
    checkArg(1, path, "string")
    checkArg(2, m, "string", "nil")
    local addr, aPath = getAddrAndPath(path)
    local handle = k.component.invoke(addr, "open", aPath, m)
    return k.create_fd({
        write = function(fd, buf)
            return k.component.invoke(addr, "write", handle, buf)
        end,
        seek = function(wh, off)
            return k.component.invoke(addr, "seek", handle, wh, off)
        end,
        read = function(c)
            return k.component.invoke(addr, "read", handle, c)
        end,
        close = function()
            k.component.invoke(addr, "close", handle)
        end
    })
end

function k.rootfs.seek(fd, wh, off)
    checkArg(1, fd, "number")
    checkArg(2, _whence, "number")
    checkArg(3, offset, "number")
    if not k.isOpen(fd) then return nil, k.errno.EBADFD end
    return k.seek(fd, wh, off)
end

function k.rootfs.makeDirectory(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "makeDirectory", aPath)
end

function k.rootfs.exists(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "exists", aPath)
end

function k.rootfs.isReadOnly(path)
    checkArg(1, path, "string")
    local addr, _ = getAddrAndPath(path)
    return k.component.invoke(addr, "isReadOnly")
end

function k.rootfs.write(fd, buf)
    checkArg(1, fd, "number")
    checkArg(2, buf, "string")
    if not k.isOpen(fd) then return nil, k.errno.ECLOSED end
    return k.write(fd)
end

function k.rootfs.spaceTotal(path)
    checkArg(1, path, "string")
    local addr, _ = getAddrAndPath(path)
    return k.component.invoke(addr, "spaceTotal")
end

function k.rootfs.isDirectory(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "isDirectory", aPath)
end

function k.rootfs.rename(from, to)
    checkArg(1, from, "string")
    checkArg(2, to, "string")
    local addr, aFrom = getAddrAndPath(path)
    local addr2, aTo = getAddrAndPath(path)
    if addr ~= addr2 then return nil, k.errno.EDEVSWT end
    return k.component.invoke(addr, "rename", aFrom, aTo)
end

function k.rootfs.list(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "list", aPath)
end

function k.rootfs.lastModified(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "lastModified", aPath)
end

function k.rootfs.getLabel(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "getLabel")
end
function k.rootfs.remove(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "remove", aPath)
end

function k.rootfs.close(fd)
    checkArg(1, fd, "number")
    if not k.isOpen(fd) then return nil, k.errno.EBADFD end
    k.close(fd)
end

function k.rootfs.size(path)
    checkArg(1, path, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "size", aPath)
end

function k.rootfs.read(fd, count)
    checkArg(1, fd, "number")
    checkArg(2, count, "number")
    if not k.isOpen(fd) then return nil, k.errno.ECLOSED end
    return k.read(fd, count)
end

function k.rootfs.setLabel(path, value)
    checkArg(1, path, "string")
    checkArg(2, value, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "setLabel", value)
end

---------------------------------------

function k.rootfs.getAttrs(path)
    checkArg(1, path, "string")
    checkArg(2, value, "string")
    local addr, aPath = getAddrAndPath(path)
    return k.component.invoke(addr, "getAttrs", aPath)
end

function k.rootfs.ensureOpen(fd)
    checkArg(1, fd, "number")
    return k.isOpen(fd)
end