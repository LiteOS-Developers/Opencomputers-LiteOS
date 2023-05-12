return {
    main = function(args)
        local lfs = require("System.lfs")
        
        -- -- print(dump(lfs.read("/dev/hd0p1")))
        -- -- print(dump(lfs.findFreeEntry("/dev/hd0p1", "/")))
        -- -- lfs.createFileEntry("/dev/hd0p1", "/", "FileB.txt", {
        -- --     firstSector = 11,
        -- -- })
        -- -- local results, e = lfs.findEntryDeep("/dev/hd0p1", "/", "FileB.txt")
        -- -- print(dump{results, e})
        -- -- print(dump({lfs.allocateFreeSector("/dev/hd0p1", "/DirA", true)}))
        -- -- print(dump({lfs.writeFile("/dev/hd0p1", "/DirA/FileA.txt", "Hello World")}))
        -- -- print(lfs.getContent("/dev/hd0p1", "/DirA/FileA.txt"))
        local api = lfs.mount("/dev/hd0p1")
        local start = computer.uptime()
        local handle = api.open("/DirA/FileA.txt", "r")
        print(api.read(handle, 11))
        api.close(handle)
        print(string.format("%.3f", computer.uptime() - start))

        
    end
}


