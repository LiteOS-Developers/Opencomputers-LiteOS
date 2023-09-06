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

k.printk(k.L_INFO, "scheduler/loop")

local processes = {}
local current = 0
local pid = 0
function k.add_process()
    pid = pid+1
    processes[pid] = k.create_process(pid, processes[current])
    return pid
end

function k.get_process(rpid)
    checkArg(1, rpid, "number")
    return processes[rpid]
end

function k.is_pgroup(id)
    return not not (processes[id] and processes[id].pgid == id)
end

function k.get_pids()
    local procs = {}
    for ppid in pairs(processes) do
        procs[#procs + 1] = ppid
    end
    return
end

  -- return all the PIDs in a process group
function k.pgroup_pids(id)
    local result = {}
    if not k.is_pgroup(id) then return result end

    for pid, proc in pairs(processes) do
        if proc.pgid == id then
            result[#result+1] = pid
        end
    end
    return result
end

function k.remove_process(pid)
    checkArg(1, pid, "number")
    processes[pid] = nil
    return true
end

function k.current_process()
    return processes[current]
end

local default = {n = 0}


function k.scheduler_loop()
    last_yield = 0
    local last_time = os.time()
    while processes[1] do
        k.pullSignal(0.05)
        local deadline = math.huge
        for _, process in pairs(processes) do
            local proc_deadline = process:deadline()
            if proc_deadline < deadline then
                deadline = proc_deadline
                if deadline < 0 then break end
            end
        end
        
        local signal = default
        if deadline == -1 then
            if computer.uptime() - last_yield > 4 then
                last_yield = computer.uptime()
                signal = table.pack(k.pullSignal(0))
            end
        else
            last_yield = computer.uptime()
            signal = table.pack(k.pullSignal(deadline - computer.uptime()))
        end
        for cpid, process in pairs(processes) do
            if not process.is_dead then
                current = cpid
                if computer.uptime() >= process:deadline() or #signal > 0 then
                    process:resume(table.unpack(signal, 1, signal.n))
                    if not next(process.threads) then
                        
                        -- close all open files
                        for _, fd in pairs(process.fds) do
                            k.close(fd)
                        end

                        -- remove all signal handlers
                        for id in pairs(process.handlers) do
                            k.remove_signal_handler(id)
                        end
                        process.is_dead = true
                        --processes[process.pid] = nil
                    end
                end
                -- k.printk(k.L_DEBUG, "Running PID: %d %s %s", process.pid, dump(process.cmdline), tostring(process.is_dead))
            else
                if not processes[process.ppid] then
                    process.ppid = 1
                end
            end
        end
    end
end
