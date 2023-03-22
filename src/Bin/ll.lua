local fs = filesystem

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
local function toint(n)
    checkArg(1, n, "number")
    return string.format("%.0f", n)
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
        local shell = require("Shell").connect("tty0")
        local dir = shell:chdir()
        local gpu = fs.open("/dev/gpu")
        if #args >= 2 then
            dir = shell:resolvePath(args[2])
            if not fs.isDirectory(dir) then
                ioctl(gpu, "setForeground", 0xF00000)
                shell:print("cd: So such directory: " .. tostring(dir))
                ioctl(gpu, "setForeground", 0xFFFFFF)
                fs.close(gpu)
                return
            end
        end
        if dir == "" then dir = "/" end 
        local size = 0 
        local abs = ""
        shell:print("Contents in " ..dir .. ":")

        local files = fs.listDir(dir)
        files.n = nil
        local cursor = fs.open("/dev/cursor")
        local x, y = ioctl(cursor, "get")
        local w, h = ioctl(gpu, "getResolution")
        -- local buffer = ioctl(gpu, "allocateBuffer", w, h)
        -- ioctl(gpu, "bitblt", buffer, 1, 1, w, h, 0, 1, 1)
        -- local r = ioctl(gpu, "setActiveBuffer", buffer)
        for _, v in ipairs(files) do
            abs = dir .. "/" .. v
            if abs:sub(1, 2) == "//" then abs = abs:sub(2, -1) end
            size = fs.getFilesize(abs)
            -- print(tostring(tostring(toint(size))))
            local t = "-rw " .. trunc(tostring(toint(size)), 7) .. " " .. formatDate(fs.getLastEdit(abs)/1000) .. " "

            x = t:len() + 1
            if fs.isFile(abs) then
                t = "f"..t
                ioctl(gpu, "set", 1, y, t .. v)
                -- print(t .. v)
                -- ioctl(gpu, "setForeground", 0x00F000)
                -- ioctl(gpu, "set", x, y, v)
                -- ioctl(gpu, "setForeground", 0xFFFFFF)
            else
                t = "d".. t
                ioctl(gpu, "set", 1, y, t .. v)
                -- print(t .. v)

                -- ioctl(gpu, "setForeground", 0x0000F0)
                -- ioctl(gpu, "set", x, y, v)
                -- ioctl(gpu, "setForeground", 0xFFFFFF)
            end
            y = y + 1
            if y > h then
                ioctl(gpu, "copy", 1, 2, w, h - 1, 0, -1)
                ioctl(gpu, "fill", 1, h, w, 1, " ")
                y = y - 1
            end
        end
        x = 1
        


        ioctl(cursor, "set", x, y)
        fs.close(cursor)
        -- ioctl(gpu, "bitblt", 0, 1, 1, w, h, buffer, 1, 1)
        -- local r = ioctl(gpu, "setActiveBuffer", 0)
        -- ioctl(gpu, "freeBuffer", buffer)
        fs.close(gpu)
        return 0
    end
}