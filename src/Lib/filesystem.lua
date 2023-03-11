local api = {}



api.open = function(path, mode)
    return syscall("fdopen", path, mode)
end
api.listDir = function(dir)
    return syscall("fdListDir", dir)
end
api.isFile = function(file)
    return syscall("isFile", file)
end
api.isDirectory = function(file)
    return syscall("isDirectory", file)
end
api.getFilesize = function(file)
    return syscall("fdSize", file)
end
api.getLastEdit = function(file)
    return syscall("fdLastEdit", file)
end