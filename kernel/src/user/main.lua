--#ifdef SYSCALLS
k.register_syscall("ioctl", function(...)
    k.ioctl(...)
end)
--#endif
--#include "user/sandbox.lua"
--#include "user/exec.lua"
--#include "user/auth.lua"
--#include "user/init.lua"