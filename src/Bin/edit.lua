local gpu
local cursor
local fs = filesystem
local buffer = {{}}
local pos = {1, 1}
local screenPos = {1, 1} -- {x, y} x: Line; y: Column
local w, h 


local function bgReset()
    ioctl(gpu, "setForeground", 0xFFFFFF)
    ioctl(gpu, "setBackground", 0x000000)
end

local function clear()
    local w, h = ioctl(gpu, "getResolution")
    bgReset()
    ioctl(gpu, "fill", 1, 1, w, h, " ")
    ioctl(cursor, "set", 1, 1)
end

local function min(a, b)
    checkArg(1, a, "number")
    checkArg(2, b, "number")
    if a > b then return b end
    return a
end

local editor = {}

editor.frame = function(name)
    assert(gpu ~= cursor, "Called rendering before initialized!")
    checkArg(1, name, "string")
    ioctl(gpu, "setBackground", 0xF1F1F1)
    ioctl(gpu, "setForeground", 0x000000)   
    local toFill = (w - name:len()) / 2
    ioctl(gpu, "fill", 1, 1, toFill, 1, " ")
    ioctl(gpu, "set", toFill, 1, name)
    ioctl(gpu, "fill", toFill + name:len(), 1, w, 1, " ")
    bgReset()
    ioctl(gpu, "set", 1, h, ":")
end

-- editor.printFile = function()
--     ioctl(cursor, "set", 1, 2)
--     bgReset()
--     -- ioctl(gpu, "fill", 1, 2, w, h - 1, " ")

--     for i = screenPos[1], min(h - 2, #buffer) do
--         print(table.concat(buffer[i]))
--     end
--     -- print(dump(buffer))
--     -- print("===")
-- end

editor.calcShift = function()
    if screenPos[1] >= h - 1 then
        return 1
    elseif screenPos[1] <= 2 then
        return -1
    end
    return 0
end


return {
    main=function(args)
        local name = args[2]
        if not name then
            name = "New Buffer"
        end
        gpu = fs.open("/dev/gpu")
        cursor = fs.open("/dev/cursor")
        w,h = ioctl(gpu, "getResolution")
        local shell = require("Shell").connect("tty0")
        clear()
        editor.frame(name)
        ioctl(cursor, "set", 1, 2)

        while true do
            local d = event.pull("key_down")
            -- print(dump(d))
            local char, code = d[3], d[4]
            if char == 0 and code == 200 then -- keyup
            elseif char == 0 and code == 203 then -- keyleft
            elseif char == 0 and code == 205 then -- keyright
            elseif char == 0 and code == 208 then -- keydown
            elseif char == 13 and code == 28 then -- enter
                pos[1] = pos[1] + 1
                table.insert(buffer, pos[1], {})
                -- print(dump(buffer))
                screenPos[1] = screenPos[1] + 1
                screenPos[2] = 1
                pos[2] = 1
            elseif char == 8 and code == 14 then -- backspace
                if screenPos[2] >= 2 then
                    table.remove(buffer[pos[1]], pos[2])
                    pos[2] = pos[2] - 1
                    screenPos[2] = screenPos[2] - 1
                    ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, " ")
                elseif screenPos[2] == 1 and pos[1] >= 2 then
                    table.remove(buffer, pos[1])
                    pos[1] = pos[1] - 1
                    pos[2] = #buffer[pos[1]] + 1
                    screenPos[1] = screenPos[1] - 1
                    screenPos[2] = pos[2] 
                    -- TODO: REDRAW lines below
                end
            else
                local localChar = utf8.char(char)
                if localChar == "\t" then -- tab
                elseif char ~= 0 or char ~= 8 or char ~= 9 or char ~= 13 then
                    table.insert(buffer[pos[1]], pos[2], localChar)
                    ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, localChar)
                    pos[2] = pos[2] + 1
                    screenPos[2] = screenPos[2] + 1

                end
            end
        end

        fs.close(event)
        fs.close(gpu)
        fs.close(cursor)
        return 0
    end
}