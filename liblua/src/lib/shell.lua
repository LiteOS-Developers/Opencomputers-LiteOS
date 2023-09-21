local p = table.pack
local u = table.unpack

local proc = syscall("pstat", syscall("getpid"))
if #table.keys(proc) == 0 or proc.shell == nil then
    error("Invalid result from pstat: Empty")
    syscall("exit", -100)
    return {}
end

local handle = syscall("open", proc.shell, "r")

return {
    chdir = function(dir)
        checkArg(1, dir, "string", "nil")
        return u(p(ioctl(handle, "chdir", dir)))
    end,
    getcwd = function()
        return u(p(ioctl(handle, "chdir")))
    end,
    resolve = function(bin)
        checkArg(1, bin, "string")
        return u(p(ioctl(handle, "resolve", bin)))
    end,
    execute = function(path, a)
        checkArg(1, path, "string")
        checkArg(2, a, "table")
        return u(p(ioctl(handle, "execute", path, a)))
    end
}