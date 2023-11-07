local shell = require("Shell")
local uuid = require("uuid")

local function trunc(str, len)
    checkArg(1, str, "string")
    checkArg(2, len, "number")
    if string.len(str) >= len then return string.sub(str, 1, len) end

    local toFill = max(len, tonumber(math.abs(len - str:len())))
    repeat
        str = str .. " "
        toFill = toFill - 1
    until toFill == 0
    return str
end

local function toint(n)
    checkArg(1, n, "number")
    return string.format("%.0f", n)
end

return {
    main=function(args)
        local sh = shell.connect("tty0")
        local ps = filesystem.open("/dev/ps")
        local processes = ioctl(ps, "list")
        print("PID    NAME               TIME")
        for pid, o in pairs(processes) do
            -- print(tostring(o.created))
            print(string.format("%-5s  %-15s   %+5s", toint(o.pid), o.name:sub(1, 15), string.format("%.1f", computer.uptime() -    (o.started or o.created))))
        end
        filesystem.close(ps)
        return 0
    end
}