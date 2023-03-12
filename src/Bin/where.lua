return {
    main = function(granted, args)
        local shell = getTTY("tty")
        if #args >= 1 then
            shell:print(shell:resolve(args[1]))
            return 0
        else
            shell:print("Missing Argument: \n  Usage: where <file>")
            return 1
        end
    end
}