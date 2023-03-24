local gpu
local cursor
local fs = filesystem
local buffer = {{}}
local pos = {1, 1}
local screenPos = {1, 1} -- {x, y} x: Line; y: Column
local w, h 
local gpuBuffer
local renderer = {}
local running = true


-- local call = ioctl
-- local callBuffer = {}
-- function ioctl(handle, func, ...)
--     -- callBuffer[#callBuffer + 1] = {handle=handle,func=func, args=table.pack(...)}
-- end

-- local function invoke()
--     for i=1,#callBuffer do
--         local v = callBuffer[i]
--         syscall("ioctl", v.handle, f.func, table.unpack(v.args))
--     end
-- end


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

editor.calcShift = function()
    if screenPos[1] >= h - 1 then
        return 1
    elseif screenPos[1] <= 2 then
        return -1
    end
    return 0
end

editor.removeCursor = function()
    -- renderer[#renderer+1] = {"get", screenPos[2], screenPos[1] + 1}
    -- local char = ioctl(gpu, "get", screenPos[2], screenPos[1] + 1)
    -- renderer[#renderer+1] = {"setForeground", 0xFFFFFF}
    -- renderer[#renderer+1] = {"setBackground", 0x000000}
    -- renderer[#renderer+1] = {"set", screenPos[2], screenPos[1] + 1, char}

    -- bgReset()
    -- ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, char)
    -- render()
end

editor.showCursor = function()
    local chr = ioctl(gpu, "get", screenPos[2], screenPos[1] + 1)
    -- ioctl(gpu, "setBackground", 0xF1F1F1)
    -- ioctl(gpu, "setForeground", 0x000000)
    -- ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, chr)

    -- renderer[#renderer+1] = {"get", screenPos[2], screenPos[1] + 1}
    -- renderer[#renderer+1] = {"setForeground", 0x000000}
    -- renderer[#renderer+1] = {"setBackground", 0xF1F1F1}
    -- renderer[#renderer+1] = {"set", screenPos[2], screenPos[1] + 1, chr}
    -- render()
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
        -- gpuBuffer = ioctl(gpu, "allocateBuffer", w, h)
        clear()
        -- ioctl(gpu, "setActiveBuffer", gpuBuffer)
        editor.frame(name)
        editor.showCursor()
        -- print("WORKS!")
        -- render()
    
        
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
                -- buffer[pos[1]] = {}
                -- print(dump(buffer))
                editor.removeCursor()
                screenPos[1] = screenPos[1] + 1
                screenPos[2] = 1
                editor.showCursor()
                render()
                pos[2] = 1
            elseif char == 8 and code == 14 then -- backspace
                if screenPos[2] >= 2 then
                    table.remove(buffer[pos[1]], pos[2])
                    editor.removeCursor()
                    pos[2] = pos[2] - 1
                    screenPos[2] = screenPos[2] - 1
                    editor.showCursor()
                    ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, " ")
                elseif screenPos[2] == 1 and pos[1] >= 2 then
                    table.remove(buffer, pos[1])
                    editor.removeCursor()
                    pos[1] = pos[1] - 1
                    pos[2] = #buffer[pos[1]] + 1
                    screenPos[1] = screenPos[1] - 1
                    screenPos[2] = pos[2] 
                    editor.showCursor()
                    render()
                    -- TODO: REDRAW lines below current
                end
            else
                local localChar = utf8.char(char)
                if localChar == "\t" then -- tab
                elseif localChar == "\x03" then
                    local d2 = event.pull("key_down")
                    char2, code2 = d2[3], d2[4]
                    if char2 ~= char ~= 0 or char ~= 8 or char ~= 9 or char ~= 13 then
                        local localized = utf8.char(char2)
                        ioctl(gpu, "set", 2, h, localized)
                        editor.removeCursor()
                        local screen = screenPos
                        screenPos = {2, h}
                        editor.showCursor()
                        if localized == "q" then
                            clear()
                            render()
                            break
                        else
                            editor.removeCursor()
                            screenPos = screen
                            editor.showCursor()
                            ioctl(gpu, "set", 2, h, "No Action")
                            -- render()
                        end
                        -- todo: Add More
                    end
                elseif char ~= 0 or char ~= 8 or char ~= 9 or char ~= 13 then
                    -- render()
                    table.insert(buffer[pos[1]], pos[2], localChar)
                    editor.removeCursor()
                    ioctl(gpu, "set", screenPos[2], screenPos[1] + 1, localChar)
                    pos[2] = pos[2] + 1
                    screenPos[2] = screenPos[2] + 1
                    editor.showCursor()
                    -- render()
                end
                
            end
            render()
        end

        -- ioctl(gpu, "setActiveBuffer", 0)
        ioctl(gpu, "freeBuffer", gpuBuffer)
        running = false
        clear()
        fs.close(gpu)
        -- fs.close(cursor)
        return 0
    end
}