--#include "drivers/devfs.lua"
k.devfs = k.devfs.create()
--#include "drivers/rootfs.lua"

--#include "drivers/vcomponent.lua"
--#ifdef COMPONENT
k.component.register(k.devfs.addr, "filesystem", k.devfs)
--#endif