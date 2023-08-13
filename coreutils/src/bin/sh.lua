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
            end
            i = i + 1
        end
        if parsed.command ~= nil then
            syscall("fork", function()
                syscall("execve", parsed.command, {})
            end)
        end
    end
}