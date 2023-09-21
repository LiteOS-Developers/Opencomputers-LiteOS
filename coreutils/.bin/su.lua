return {
    main = function(args)
        local shell = require("Shell").connect("tty0")
        result = shell.auth()
        return 0
    end
}