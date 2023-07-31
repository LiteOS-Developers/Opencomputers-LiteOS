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

--#ifdef KERNEL
while true do
    pid, thread = k.nextThread()
    if pid == nil then
        error("System Crashed! There are no running processes!")
    end
    result = k.schedule(pid, thread)
    if result[1] == nil and result.n == 1 then
        goto continue
    end
    if not result[1] then
        error(dump(result[2]))
    end
    if coroutine.status(v.coro) == "dead" then
        k.threading.threads[pid].result = result[2]
        k.threading.threads[pid]:stop()
        goto continue
    end
    -- if result[2] == "syscall" then
    --     error("!")
    --     result = table.pack(coroutine.resume(v.coro, table.unpack({k.processSyscall(result)})))
    -- end
    ::continue::
end
--#endif