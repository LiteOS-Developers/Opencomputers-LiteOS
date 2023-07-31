--#skip 13
--[[
    Copyright (C) 2023 thegame4craft

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

do
    k.printk(k.L_INFO, "init/filesystem")
    k.printk(k.L_DEBUG, "Mounting RootFS")
    k.rootfs.mount(computer.getBootAddress(), "/", {})
    k.printk(k.L_DEBUG, "Mounting TempFS")
    k.rootfs.mount(computer.tmpAddress(), "/tmp", {})
    --#ifdef DRV_DEVFS
    k.printk(k.L_DEBUG, "Mounting DevFS")
    k.rootfs.mount(k.devfs.addr, "/dev", {})
    --#endif
    for addr, type in component.list("filesystem") do
        k.printk(k.L_DEBUG, "Mounting %s", addr:sub(1,3))
        k.rootfs.mount(addr, "/mnt/" .. addr:sub(1,3), {})
    end
end