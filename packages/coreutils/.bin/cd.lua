return {
    main=function(args)
        local shell = require("Shell").connect("tty0")

        if #args >= 2 then
            local dir = shell:resolvePath(args[2])
            if filesystem.isDirectory(dir) then
                shell:chdir(dir)
            else
                local gpu = filesystem.open("/dev/gpu")
                ioctl(gpu, "setForeground", 0xF00000)
                shell:print("cd: No such directory: " .. tostring(dir))
                ioctl(gpu, "setForeground", 0xFFFFFF)
                filesystem.close(gpu)
            end
        else
            shell:print(dump(shell:chdir()))
        end
    end
}