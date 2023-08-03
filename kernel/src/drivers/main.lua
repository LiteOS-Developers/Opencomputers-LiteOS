--#include "drivers/devfs.lua"
--#include "drivers/rootfs.lua"
--#include "drivers/vcomponent.lua"

k.devfs = k.devfs.create()
--#ifdef COMPONENT
k.component.register(k.devfs.addr, "filesystem", k.devfs)
--#endif