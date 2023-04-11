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
                shell:print("ll: So such directory: " .. tostring(dir))
                ioctl(gpu, "setForeground", 0xFFFFFF)
                fs.close(gpu)
                return
            end
        end
        if dir == "" then dir = "/" end 
        local size = 0 
        local abs = ""
        
        local files, e = fs.listDir(dir)
        if not files then
            print("ll:" .. e)
            return -1
        end
        shell:print("Contents in " ..dir .. ":")
        files.n = nil
        local abs
        for _, v in ipairs(files) do
            abs = dir .. "/" .. v
            if abs:sub(1, 2) == "//" then abs = abs:sub(2, -1) end
            local size = fs.getFilesize(abs)
            local lastEdited = fs.getLastEdit(abs)
            -- print(abs:sub(1, -2))
            -- print(abs .. " " .. dump())
            if abs:sub(-1) == "/" then abs = abs:sub(1, -2) end
            local attrs, e = filesystem.getAttrs(abs)
            if e then
                print(abs .. ": " .. dump(e))
            end
            local t = (attrs.mode or "---------") .. " " .. trunc(tostring(toint(size)), 7) .. " "
            if lastEdited == 0 then
                lastEdited = time()
            end
            t = t .. formatDate(lastEdited/1000) .. " "
            -- x = t:len() + 1
            if fs.isFile(abs) then
                print("f" .. t .. v)
            else
                print("d" .. t .. v)
            end
        end
        
        return 0
    end
}