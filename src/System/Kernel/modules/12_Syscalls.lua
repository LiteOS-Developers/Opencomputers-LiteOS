_G.k.syscalls = k.service.getService("Syscalls")

function _G.k.processSyscall(call, args)
    local call = result[3]
    local data = result[4] or {}

    if syscalls[call] ~= nil then
        -- _G.write(dump(table.unpack(data)))
        result, err = xpcall(syscalls[call], debug.traceback, data)
        if not result then
            -- coroutine.resume(v.coro, nil, err)
            return nil, err
        end
        local r = table.pack(err)
        -- coroutine.resume(v.coro, r, err)
        return r, err
    else
        return nil, "Syscall not found"
    end
end