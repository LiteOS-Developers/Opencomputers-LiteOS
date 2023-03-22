local shell = require("Shell")
local uuid = require("uuid")

return {
    main=function(args)
        local sh = shell.connect("tty0")
        sh:print(uuid.next())
        sh:print(uuid.next())
    end
}