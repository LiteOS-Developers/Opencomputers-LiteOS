local function exec(cmd, args)
    checkArg(1, cmd, "string")
    checkArg(2, args, "table", "nil")

    if not syscall("exists", cmd) then
        return -1, 2 -- ENOENT
    elseif syscall("isDirectory", cmd) then
        return -1, 21 -- EISDIR
    end
    local pid, errno = syscall("fork", function()
        local _, errno = syscall("execve", "/bin/sh.lua", {
            "-c",
            cmd,
            "--",
            table.unpack(args or {})
        })
        if not _ then
            printf("getty: execve failed: %d: %s\n", tonumber(errno or -1), tostring(_))
            syscall("exit", 1)
        end
    end)
    coroutine.yield(0)

    if not pid then
        printf("getty: fork failed: %d\n", errno)
        return nil, errno
    else
        return pid
    end
end

return {
    main = function(...)
        local device = {
            dir = "",
            env = {
                PATH = "/bin:/usr/bin"
            },
        }
        device.chdir = function(dir)
            checkArg(1, dir, "string", "nil")
            if type(dir) == "nil" then return device.dir end
            device.dir = dir
            return dir
        end

        device.resolve = function(cmd)
            checkArg(1, cmd, "string")
            if cmd:sub(1,2) == "./" then
                cwd = device.dir
                if cwd:sub(-1,-1) ~= "/" then
                    cwd = cwd .. "/"
                end
                return cwd .. cmd
            elseif cmd:sub(1,1) == "/" then
                return cmd
            end
            if string.find(cmd, "/") ~= nil then
                return nil
            end
            for _, p in ipairs(split(device.env.PATH, ":")) do
                if p:sub(-1,-1) ~= "/" then p = p .. "/" end
                if syscall("exists", p .. cmd .. ".lua") then
                    if not syscall("isDirectory", p .. cmd .. ".lua") then
                        return p .. cmd .. ".lua"
                    end
                end
            end
            return nil
        end

        device.execute = function(cmd, args)
            checkArg(1, cmd, "string")
            checkArg(2, args, "table", "nil")
            local pid, errno = exec(cmd, args)
            return pid,errno
        end

        local mt = {
            __index = device
        }

        local success, errno = syscall("mkdev", "tty0", setmetatable({}, mt))
        if not success then
            printf("getty: Cannot register device tty0: %d\n", errno or -1)
        end
        local user = syscall("getSession")
        
        exec(user.shell:sub(1,-2))

    end
}