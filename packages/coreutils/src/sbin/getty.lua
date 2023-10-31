return {
    main = function(...)
        local user = syscall("getSession")

        local success, errno = syscall("mknod", "/dev/tty0", "c8.0")
        if not success then
            printf("getty: Cannot register device tty0: %d\n", errno or -1)
            syscall("exit", -1)
        end
        local handle, e = syscall("open", "/dev/tty0")
        if not handle then
            printf("getty: Cannot connect to /dev/tty0: %d", e)
            syscall("exit", -1)
        end
        ioctl(handle, "chdir", user.home)
        ioctl(handle, "execute", user.shell:sub(1,-2))

    end
}