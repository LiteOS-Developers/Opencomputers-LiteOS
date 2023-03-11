local api = {}



api.open = function(path, mode)
    return syscall("fdopen", path, mode)[1]
end
api.listDir = function(dir)
    return syscall("fListDir", dir)[1]
end
api.isFile = function(file)
    return syscall("isFile", file)[1]
end
api.isDirectory = function(file)
    return syscall("isDirectory", file)[1]
end
api.getFilesize = function(file)
    return syscall("fSize", file)[1]
end
api.getLastEdit = function(file)
    return syscall("fLastEdit", file)[1]
end
return api