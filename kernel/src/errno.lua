
k.printk(k.L_INFO, "errno")

do
  k.errno = {
    EPERM = 1,
    ENOENT = 2,
    ESRCH = 3,
    ENOEXEC = 8,
    EBADF = 9,
    ECHILD = 10,
    EACCES = 13,
    ENOTBLK = 15,
    EBUSY = 16,
    EEXIST = 17,
    EXDEV = 18,
    ENODEV = 19,
    ENOTDIR = 20,
    EISDIR = 21,
    EINVAL = 22,
    ENOTTY = 25,
    ENOSYS = 38,
    EUNATCH = 49,
    ELIBEXEC = 83,
    ENOPROTOOPT = 92,
    ENOTSUP = 95,
    ECLOSED = 1001,
    EDEVSWT = 1002 -- E_DEVICE_SWITCH
  }
end