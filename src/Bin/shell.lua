local shell = require("Shell")
local fs = filesystem

_G.print = print


return {
    main = function(args)
        local sh = shell.connect("tty")
        _G.print("======")
        sh:print("Hello World")
        
        -- local res, err = scall(sh.read, sh, ">>> ")
        -- print("Result: " .. dump({res, err}))
        print("======")
        return 0
    end
}