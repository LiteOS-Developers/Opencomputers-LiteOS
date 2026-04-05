--#ifdef SYSCALLS
k.register_syscall("ioctl", function(...)
    return table.unpack({k.ioctl(...)})
end)
--#endif
--#include "./sandbox.lua"
--#include "./exec.lua"
--#include "./auth.lua"
--#include "./init.lua"
