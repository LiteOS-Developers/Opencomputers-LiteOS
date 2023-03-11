local fs = require("filesystem")

local function max(max, v) 
    checkArg(1, max, "number")
    checkArg(2, v, "number")
    if max < v then
        return max
    end
    return v
end

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

local function formatDate(epochms)
    --local day_names={"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"}
    local month_names={"January","February","March","April","May","June","July","August","September","October","November","December"}
    if epochms == 0 then return "" end
    local d = os.date("*t", epochms)
    local day, hour, min, sec = nod(d.day), pad(nod(d.hour)), pad(nod(d.min)), pad(nod(d.sec))
    return string.format("%s-%s-%s %s:%s:%s ", d.year, pad(nod(d.month)), pad(day), hour, min, sec)
end

return {
    features = {},
    main=function(granted, args)
        local shell = getTTY("tty0")
        -- _G.write(dump(shell))
        local dir = shell:getpwd()
        if #args >= 2 then
            dir = shell:resolvePath(args[2])
            if not fs.isDirectory(dir) then
                shell:setFore(0xF00000)
                shell:print("cd: So such directory: " .. tostring(dir))
                shell:setFore(0xFFFFFF)
            end
        end
        local size = 0 
        local abs = ""
        local files = fs.listDir(dir)
        files.n = nil
        local gpu = shell:getGPU()
        local w,h = gpu.getResolution()
        local line = 0
        for k, v in pairs(files) do
            abs = dir .. "/" .. v
            if line + string.len(v) + 2 > w then
                shell:print("")
            end
            if fs.isFile(abs) then
                size = fs.getFilesize(abs)
                shell:setFore(0x00F000)
                shell:print(v .. "  ", false)
                line = line + string.len(v) + 2
                shell:setFore()
            else
                shell:setFore(0x0000F0)
                shell:print(string.sub(v, 1, -2) .. "  ", false)
                shell:setFore()
            end
        end
        shell:print(" ",true)
    end
}