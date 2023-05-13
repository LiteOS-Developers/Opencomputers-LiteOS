return {
    main = function(args)
        local lfs = require("System.lfs/drive")
        lfs.mount("/dev/hd0p1", "/drive")
        
    end
}


