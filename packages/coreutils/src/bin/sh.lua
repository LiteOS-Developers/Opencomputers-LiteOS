return {
    main = function(args)
        args[0] = nil
        local parsed = {}
        local i = 1
        while i <= #args do
            local a = args[i]
            if a == "-c" then
                i = i + 1
                parsed["command"] = args[i]
            elseif a == "--" then
                parsed["args"] = {}
                i = i + 1
                while i <= #args do
                    table.insert(parsed["args"], args[i])
                    i = i + 1
                end
            end
            i = i + 1
        end
        if parsed.command ~= nil then
            local pid, e = syscall("fork", function()
                syscall("execve", parsed.command, parsed.args or {})
            end)
            if not pid then
                printf("sh: fork failed: %d\n", e)
                syscall("exit", -1)
                return
            end
            syscall("wait", pid)
        else
            printf("No command specified: \n%s\n", dump(parsed))
            -- printf("%s\n", dump(args))
        end
    end
}