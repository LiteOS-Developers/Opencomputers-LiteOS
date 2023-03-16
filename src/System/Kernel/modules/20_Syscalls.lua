k.syscalls, err = k.service.getService("Syscalls")
if not k.syscalls then
    error(dump(err))
end

function k.processSyscall(call, args)
    if k.syscalls[call] ~= nil then
        
        result, err = xpcall(function() return k.syscalls[call](table.unpack(args)) end, debug.traceback)
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