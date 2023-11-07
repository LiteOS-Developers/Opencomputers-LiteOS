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
do
    local filesystem = {}
    function filesystem.open(path, mode)
        checkArg(1, path, "string")
        checkArg(2, mode, "string")
        return syscall("fopen", path, mode)
    end
    function filesystem.write(fd, buf)
        checkArg(1, fd, "number")
        checkArg(2, buf, "string")
        return syscall("write", fd, buf)
    end
    function filesystem.read(fd, c)
        checkArg(1, fd, "number")
        checkArg(2, c, "number", "string")
        return syscall("read", fd, c)
    end
    function filesystem.seek(fd, off, whe)
        checkArg(1, fd, "number")
        checkArg(2, off, "number")
        checkArg(2, whe, "string")
        return syscall("seek", fd, off, whe)
    end
    function filesystem.close(fd)
        checkArg(1, fd, "number")
        return syscall("close", fd)
    end
    function filesystem.makeDirectory(path)
        checkArg(1, path, "string")
        return syscall("makeDirectory", path)
    end
    function filesystem.spaceUsed(path)
        checkArg(1, path, "string")
        return syscall("spaceUsed", path)
    end
    function filesystem.exists(path)
        checkArg(1, path, "string")
        return syscall("exists", path)
    end
    function filesystem.isReadOnly(path)
        checkArg(1, path, "string")
        return syscall("isReadOnly", path)
    end
    function filesystem.spaceTotal(path)
        checkArg(1, path, "string")
        return syscall("spaceTotal", path)
    end
    function filesystem.isDirectory(path)
        checkArg(1, path, "string")
        return syscall("isDirectory", path)
    end
    function filesystem.rename(from, to)
        checkArg(1, from, "string")
        checkArg(2, to, "string")
        return syscalls("rename", from, to)
    end
    function filesystem.list(path)
        checkArg(1, path, "string")
        return syscall("list", path)
    end
    function filesystem.lastModified(path)
        checkArg(1, path, "string")
        return syscall("lastModified", path)
    end
    function filesystem.getLabel(path)
        checkArg(1, path, "string")
        return syscall("getLabel", path)
    end
    function filesystem.remove(path)
        checkArg(1, path, "string")
        return syscall("remove", path)
    end
    function filesystem.size(path)
        checkArg(1, path, "string")
        return syscall("size", path)
    end
    function filesystem.setLabel(path, value)
        checkArg(1, path, "string")
        checkArg(2, value, "string")
        return syscall("setLabel", path, value)
    end
    return filesystem
end