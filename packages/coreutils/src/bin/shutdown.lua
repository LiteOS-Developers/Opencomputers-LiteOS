return {
    main = function(args)
        local handle, result = syscall("open", "/proc/signals", "rw")
        if not handle then
            error("shutdown failed: " .. tostring(result))
        end
        ioctl(handle, "shutdown")
    end
}