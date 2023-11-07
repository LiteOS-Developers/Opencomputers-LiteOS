local computer = require("computer")

return {
    main=function(args)
        syscall("shutdown")
    end
}