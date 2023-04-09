k.printk(k.L_INFO, " - 99_time")

local function trunc(str, len)
    checkArg(1, str, "string")
    checkArg(2, len, "number")
    if len - string.len(str) < 0 then str = string.sub(str, 1, len) end
    local toFill = max(len, tonumber(math.abs(len - string.len(str))))
    repeat
        str = str .. " "
        toFill = toFill - 1
    until toFill == 0
    return str
end
local function nod(n)
    return n and (tostring(n):gsub("(%.[0-9]+)0+$","%1")) or "0"
end
local function pad(txt)
    txt = tostring(txt)
    return #txt >= 2 and txt or "0"..txt
end

local function formatDate(epochms, fmt)
    checkArg(1, epochms, "number")
    checkArg(2, fmt, "string", "nil")
    fmt = fmt or "nil"

    local month_names={"January","February","March","April","May","June","July","August","September","October","November","December"}
    if epochms == 0 then return "" end
    local d = os.date("*t", epochms)
    local day, hour, min, sec = nod(d.day), pad(nod(d.hour)), pad(nod(d.min)), pad(nod(d.sec))
    return string.format(fmt, d.year, pad(nod(d.month)), pad(day), hour, min, sec)
end

k.time = function()
    local file = filesystem.open("/tmp/time", "w")
    filesystem.close(file)
    local time = filesystem.getLastEdit("/tmp/time")
    filesystem.remove("/tmp/time")
    return time
end
