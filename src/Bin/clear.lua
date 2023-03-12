return {
    main=function(args)
        local tty = getTTY("tty")
        if tty == nil then
            error("No TTY Avaiable")
        end
        local w, h = tty.getGPU().getResolution()
        tty.getGPU().fill(1, 1, w, h, " ")
        syscall("resetCursor")
        return 0
    end
}