local fs = filesystem

return {
    main=function(args)
        local shell = require("Shell").connect("tty0")
        local gpu = fs.open("/dev/gpu")
        local w, h = ioctl(gpu, "getResolution")
        ioctl(gpu, "fill", 1, 1, w, h, " ")
        -- syscall("resetCursor")
        fs.close(gpu)
        local cursor = fs.open("/dev/cursor")
        ioctl(cursor, "set", 1, 1)
        fs.close(cursor)
        return 0
    end
}