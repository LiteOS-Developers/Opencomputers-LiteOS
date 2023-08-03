--#ifdef SYSCALLS
k.register_syscall("ioctl", function(handle, func, ...)
    k.devfs.ioctl(k.rootfs.handles[handle].handle, func, ...)
end)
--#endif
--#include "user/sandbox.lua"
--#include "user/exec.lua"
--#include "user/auth.lua"
--#include "user/init.lua"