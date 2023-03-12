return {
    main=function(granted, args)
        local shell = getTTY("tty")
        -- _G.write(dump(table.keys(_G.devices)))
        if #args >= 1 then
            local dir = shell:resolvePath(args[1])
            if syscall("isDirectory", dir) then
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