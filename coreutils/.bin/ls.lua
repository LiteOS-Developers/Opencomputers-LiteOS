local fs = filesystem
local shell = require("Shell")

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
    main=function(args)
        local sh = shell.connect("tty0")
        local dir = sh:chdir()
        local gpu = fs.open("/dev/gpu")
        if #args >= 2 then
            -- dir, e = pcall(sh.resolvePath, sh, args[2])
            dir = sh:resolvePath(args[2])
            -- print(dump(e))
            if not fs.isDirectory(dir) then
                ioctl(gpu, "setForeground", 0xF00000)
                sh:print("cd: So such directory: " .. tostring(dir))
                ioctl(gpu, "setForeground", 0xFFFFFF)
                fs.close(gpu)
                return
            end
        end
        local size = 0 
        local abs = ""
        local files = fs.listDir(dir)
        files.n = nil
        local cursor, err = fs.open("/dev/cursor")
        local x, y = ioctl(cursor, "get")
        local w, h = ioctl(gpu, "getResolution")
        local line = ""
        for k, v in pairs(files) do
            print("")
            abs = dir .. "/" .. v
            if x + v:len() + 2 > w and k ~= #files then
                x = 1
                y = y + 1
            end
            if fs.isFile(abs) then
                size = fs.getFilesize(abs)
                ioctl(gpu, "setForeground", 0x00F000)
                -- line = line .. v .. "  "
                ioctl(gpu, "set", x, y, v .. "  ")
                ioctl(gpu, "setForeground", 0xFFFFFF)
                x = x + v:len() + 2
            else
                ioctl(gpu, "setForeground", 0x0000F0)
                ioctl(gpu, "set", x, y, v .. "  ")
                ioctl(gpu, "setForeground", 0xFFFFFF)
                x = x + v:len() + 2
            end
        end
        -- if y >= h then
        --     ioctl(gpu, "copy", 1, 2, w, h - 1, 0, -1)
        --     ioctl(gpu, "fill", 1, h, w, 1, " ")
        --     y = y - 1
        -- end
        fs.close(gpu)
        y = y + 1
        x = 1
        ioctl(cursor, "set", x, y)
        fs.close(cursor)
        coroutine.yield()
    end
}