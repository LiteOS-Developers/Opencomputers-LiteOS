k.syscalls, err = k.service.getService("Syscalls")
if not k.syscalls then
    error(dump(err))
end

function k.processSyscall(result)
    if result[1] == true and result.n >= 3 then
        if result[2] == "syscall" then
            local call = result[3]
            local r = result
            table.remove(r, 1)
            table.remove(r, 1)
            table.remove(r, 1)
            r.n = nil
            local data = r
            -- k.write("16: " .. dump(data))

            local ok, result = k.callSyscall(call, data)
            -- k.write("Syscall: " .. dump(call) .. " " .. dump(data) .. " -> " .. dump(result))
            if not ok then
                return "syscall", nil, result
            else
                return "syscall", result, nil
            end
        end
    end
end

function k.callSyscall(call, args)
    if k.syscalls[call] ~= nil then
        local r = k.syscalls[call](table.unpack(args))
        -- k.write("9: " .. dump(call) .. " " .. dump(r) .. " " .. dump(args))
        return true, r
    else
        return false, "Syscall not found"
    end
end