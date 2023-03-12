local api = {}



api.open = function(path, mode)
    return syscall("fopen", path, mode)
end
api.read = function(handle, size)
    checkArg(1, handle, "number")
    checkArg(2, size, "number")
    return syscall("fdread", handle, size)
end
api.listDir = function(dir)
    return syscall("fListDir", dir)[1]
end
api.isFile = function(file)
    checkArg(1, file, "string")
    return syscall("isFile", file)
end
api.isDirectory = function(file)
    return syscall("isDirectory", file)
end
api.getFilesize = function(file)
    return syscall("fSize", file)
end
api.getLastEdit = function(file)
    return syscall("fLastEdit", file)
end
return api