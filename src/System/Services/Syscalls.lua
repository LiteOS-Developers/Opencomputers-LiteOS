local api = {}
local fs = k.service.getService("filesystem")

api.shutdown = function(...)
    computer.shutdown(false)
end
api.reboot = function(...)
    computer.shutdown(true)
end

api.resetCursor = function(args)
    _G.screen.x = args[1] or 1
    _G.screen.y = args[2] or 1
end

api.isFile = function(dir)
    return fs.isFile(dir)
end
api.isDirectory = function(dir)
    return fs.isDirectory(dir)
end
api.fopen = function(file, mode)
    return fs.open(file, mode)
end
api.fdread = function(handle, size)
    return fs.read(handle, size)
end
api.fdwrite = function(handle, buf)
    return fs.write(handle, buf)
end
api.fdseek = function(handle, _whence, off)
    return fs.seek(handle, _whence, off)
end
api.fdclose = function(handle)
    return fs.close(handle)
end

api.fListDir = function(dir)
    return table.pack(fs.listDir(dir))
end
api.fSize = function(file)
    return fs.getFilesize(file)
end
api.fLastEdit = function(file)
    return fs.getLastEdit(file)
end

api.ioctl = function(handle, func, ...)
    checkArg(1, handle, "number")
    checkArg(2, func, "string")
    return k.devices.ioctl(fs.getRealHandle(handle), func, ...)
end
api.ensureOpen = function(handle)
    return fs.ensureOpen(handle)
end

return api