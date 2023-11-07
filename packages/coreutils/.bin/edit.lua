local gpu
local cursor
local fs = require("filesystem")
local buffer = {{}}
local pos = {1, 1}
local screenPos = {1, 1} -- {x, y} x: Line; y: Column
local w, h 
local gpuBuffer
local renderer = {}
local running = true
local sh
local cursor
local saved


local function bgReset()
    ioctl(gpu, "setForeground", 0xFFFFFF)
    ioctl(gpu, "setBackground", 0x000000)
end

local function clear()
    local w, h = ioctl(gpu, "getResolution")
    bgReset()
    ioctl(gpu, "fill", 1, 1, w, h, " ")
    ioctl(screenCursor, "set", 1, 1)
end

local function min(a, b)
    checkArg(1, a, "number")
    checkArg(2, b, "number")
    if a > b then return b end
    return a
end

local editor = {}

editor.frame = function(name)
    assert(gpu ~= screenCursor, "Called rendering before initialized!")
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

editor.calcShift = function()
    if screenPos[1] >= h - 1 then
        return 1
    elseif screenPos[1] <= 2 then
        return -1
    end
    return 0
end

editor.removeCursor = function()
    -- local char = ioctl(gpu, "get", screenPos[2], screenPos[1] + 1)
    -- bgReset()
    -- ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, char)
end

editor.showCursor = function()
    cursor:moveTo(screenPos[2], screenPos[1] + 1)
end

editor.clearCMD = function()
    ioctl(gpu, "fill", 2, h, w, 1, " ")
end


return {
    main=function(args)
        local name = args[2]
        if not name then saved = false
        else saved = true end
        sh = require("Shell").connect("tty0")
        gpu = filesystem.open("/dev/gpu")
        screenCursor = filesystem.open("/dev/cursor")
        print("test")
        w,h = ioctl(gpu, "getResolution")
        clear()
        cursor = sh:cursor(1, 1, 0x000000, 0xFFFFFF)
        editor.showCursor()
        editor.frame(name or "New Buffer")

    
        
        while true do
            local d = event.pull("key_down")

            local char, code = d[3], d[4]
            if char == 0 and code == 200 then -- keyup
            elseif char == 0 and code == 203 and screenPos[2] > 1 then -- keyleft
                screenPos[2] = screenPos[2] - 1
                editor.showCursor()
            elseif char == 0 and code == 205 and screenPos[2] < w then -- keyright
                screenPos[2] = screenPos[2] + 1
                editor.showCursor()
            elseif char == 0 and code == 208 then -- keydown
            elseif char == 13 and code == 28 then -- enter
                pos[1] = pos[1] + 1
                table.insert(buffer, pos[1], {})
                -- buffer[pos[1]] = {}
                -- print(dump(buffer))
                screenPos[1] = screenPos[1] + 1
                screenPos[2] = 1
                editor.showCursor()
                pos[2] = 1
            elseif char == 8 and code == 14 then -- backspace
                if screenPos[2] >= 2 then
                    table.remove(buffer[pos[1]], pos[2])
                    pos[2] = pos[2] - 1
                    screenPos[2] = screenPos[2] - 1
                    ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, " ")
                    editor.showCursor()
                    if saved then saved = false end
                elseif screenPos[2] == 1 and pos[1] >= 2 then
                    table.remove(buffer, pos[1])
                    pos[1] = pos[1] - 1
                    pos[2] = #buffer[pos[1]] + 1
                    screenPos[1] = screenPos[1] - 1
                    screenPos[2] = pos[2] 
                    editor.showCursor()
                    if saved then if saved then saved = false end end
                    -- TODO: REDRAW lines below current
                end
            else
                local localChar = utf8.char(char)
                if localChar == "\t" then -- tab
                elseif localChar == "\x03" then
                    editor.clearCMD()
                    screenPos[2] = screenPos[2] - 1
                    pos[2] = pos[2] - 1
                    table.remove(buffer[pos[1]], pos[2])
                    -- editor.showCursor()
                    local screenX, screenY = screenPos[1], screenPos[2]
                    local posX, posY = pos[1], pos[2]
                    screenPos = {h - 1, 2}
                    editor.showCursor()
                    
                    local d2 = event.pull("key_down")
                    char2, code2 = d2[3], d2[4]
                    if char2 ~= 0 or char2 ~= 8 or char2 ~= 9 or char2 ~= 13 then
                        local localized = utf8.char(char2)
                        ioctl(gpu, "set", 2, h, localized)
                        local screen = screenPos
                        
                        if localized == "q" then
                            if not saved then
                                ioctl(screenCursor, "set", 1, h)
                                local yesno = sh:read("Continue without save? [y/N] ")
                                if yesno == "" or yesno == "N" or yesno == "n" then
                                    goto continue
                                else
                                    clear()
                                    break
                                end
                            end
                            clear()
                            break
                        elseif localized == "b" then
                            screenPos = {screenX, screenY}
                            pos = {posX, posY}
                            print(dump(buffer))
                        elseif localized == "w" then
                            local filepath
                            if not name then
                                ioctl(screenCursor, "set", 1, h)
                                filepath = sh:read("filepath> ")
                                ioctl(gpu, "copy", 1, 1, w, h - 1, 0, 1)
                                editor.frame(filepath)
                                name = filepath
                                editor.clearCMD()
                                ioctl(screenCursor, "set", screenY, screenX)
                            else
                                filepath = name
                            end
                            saved = true
                            local file = fs.open(filepath, "w")
                            local content = ""
                            for _, line in ipairs(buffer) do
                                content = content .. "\n" .. table.concat(line, "")
                            end
                            file:write(content:sub(2, content:len())) -- TODO: findout why there are NUL chars in file. Fixed (May not?)
                            file:close()
                            ioctl(gpu, "set", 1, h, ":File Saved")
                            screenPos = {screenX, screenY}
                            editor.showCursor()
                            goto continue
                        else
                            screenPos = {screenX, screenY}
                            editor.showCursor()
                            ioctl(gpu, "set", 2, h, "No Action")
                        end
                    end
                elseif char ~= 0 or char ~= 8 or char ~= 9 or char ~= 13 then
                    -- render()
                    table.insert(buffer[pos[1]], pos[2], localChar)
                    ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, localChar)
                    pos[2] = pos[2] + 1
                    screenPos[2] = screenPos[2] + 1
                    editor.showCursor()
                    if saved then if saved then saved = false end end
                    -- render()
                end
            end
            ::continue::
        end

        -- ioctl(gpu, "setActiveBuffer", 0)
        ioctl(gpu, "freeBuffer", gpuBuffer)
        running = false
        clear()
        filesystem.close(gpu)
        filesystem.close(screenCursor)
        return 0
    end
}