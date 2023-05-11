return {
    main = function(args)
        local lfs = require("System.lfs")
        lfs.mount("/dev/hd0p1", "/drive")
        
    end
}


