return {
    main = function(args)
        local lfs = require("System.lfs")
        if #args < 3 then
            print(string.format("%s <device> <target>", args[1]))
            return -1
        end
        lfs.mount(args[2], args[3])
    end
}


