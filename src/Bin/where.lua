local shell = require("Shell")


return {
    main = function(args)
        local sh = shell.connect("tty0")
        if #args >= 1 then
            sh:print(sh:resolve(args[1]))
            return 0
        else
            sh:print("Missing Argument: \n  Usage: where <file>")
            return 1
        end
    end
}