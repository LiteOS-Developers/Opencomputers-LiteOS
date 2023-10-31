local shell = require("shell")

return {
    main = function(args)
        local user = syscall("getSession")
        local hostname = syscall("name")
        while true do
            coroutine.yield(0)
            local cwd = shell.chdir()
            printf("%s@%s:%s# ", user.name, hostname, cwd)
            local cmd = io.stdin:read()
            args = split(cmd, " ")
            cmd = args[1]
            local a = {}
            for i = 0, #args - 1, 1 do
                a[i] = args[i+1]
            end
            if cmd ~= nil and #cmd > 0 then
                cmd = shell.resolve(cmd)
                if cmd ~= nil then
                    local pid, errno = shell.execute(cmd, a)
                    if not pid then
                        printf("execute failed with error %d\n", errno)
                    else
                        repeat
                            local proc = syscall("pstat", pid)
                            coroutine.yield(0.1)
                        until proc ~= nil
                        assert(proc == nil, "Failed!")
                    end
                else
                    printf("shell: %s not found\n", args[1])
                end
            end
        end
    end
}