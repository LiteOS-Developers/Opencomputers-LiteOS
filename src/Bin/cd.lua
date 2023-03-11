return {
    main=function(args)
        if #args >= 2 then
            local dir = shell:resolvePath(args[2])
            if service.getService("filesystem").isDirectory(dir) then
                shell:chdir(dir)
            else
                shell:setFore(0xF00000)
                shell:print("cd: No such directory: " .. tostring(dir))
                shell:setFore(0xFFFFFF)
            end
        else
            shell:print(tostring(shell:getenv("PWD")))
        end
        -- syscall("test", d)
        -- shell:print(tostring(d.a))
    end
}