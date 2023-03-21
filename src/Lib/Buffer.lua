local buffer = {}
local metatable = {
    __index = buffer,
    __metatable = "file"
  }

function buffer.new(mode, stream)
    local result = {
        closed = false,
        mode = {},
        stream = stream,
        bufferSize = math.max(512, math.min(8 * 1024, computer.freeMemory() / 8)),
        readTimeout = math.huge,
        bufferRead = "",
        bufferWrite = "",
    }
    mode = mode or "r"
    for i = 1, unicode.len(mode) do
        result.mode[unicode.sub(mode, i, i)] = true
    end
    stream.close = setmetatable({close = stream.close,parent = result},{__call = buffer.close})
    return setmetatable(result, metatable)
end

local function readChunk(self)
    local result, reason = self.stream:read(math.max(1,self.bufferSize))
    if result then
        self.bufferRead = self.bufferRead .. result
        return self
    else -- error or eof
        return result, reason
    end
end

function buffer:readLine(chop)
    if self.closed then
        return nil, "Buffer already closed"
    end
    if not self.mode.r then
        return nil, "Buffer not opened for Reading"
    end
    local start = 1
    while true do
        local buf = self.bufferRead
        local i = buf:find("[\r\n]", start)
        local c = i and buf:sub(i,i)
        local is_cr = c == "\r"
        if i and (not is_cr or i < #buf) then
            local n = buf:sub(i+1,i+1)
            if is_cr and n == "\n" then
                c = c .. n
            end
            local result = buf:sub(1, i - 1) .. (chop and "" or c)
            self.bufferRead = buf:sub(i + #c)
            return result
        else
            start = #self.bufferRead - (is_cr and 1 or 0)
            local result, reason = readChunk(self)
            if not result then
                if reason then
                    return result, reason
                else -- eof
                    result = #self.bufferRead > 0 and self.bufferRead or nil
                    self.bufferRead = ""
                    return result
                end
            end
        end
    end 
end

function buffer:seek(offset, whence)
    checkArg(1, offset, "number")
    assert(math.floor(offset) == offset, "bad argument #2 (not an integer)")

    tostring(whence or "cur")
    assert(whence == "set" or whence == "cur" or whence == "end",
    "bad argument #2 (set, cur or end expected, got " .. whence .. ")")

    if self.mode.w or self.mode.a then
        self:flush()
    elseif whence == "cur" then
        offset = offset - #self.bufferRead
    end
    local result, reason = self.stream:seek(whence, offset)
    if result then
        self.bufferRead = ""
        return result
    else
        return nil, reason
    end
end

function buffer:write_buffered(data)
    local result, reason
    if self.bufferMode == "full" then
        if self.bufferSize - #self.bufferWrite < #data then
            result, reason = self:flush()
            if not result then return nil, reason end
        end
        if #data > self.bufferSize then
            self.stream:write(data)
        else
            self.bufferWrite = self.bufferWrite .. data
            result = self
        end
    else
        local l
        repeat
            local idx = data:find("\n", (l or 0) + 1, true)
            if idx then
                l = idx
            end
        until not idx
        if l or #data > self.bufferSize then
            result, reason = self:flush()
            if not result then return nil, reason end
        end
        if l then
            result, reason = self.stream:write(data:sub(1, l))
            if not result then return nil, reason end
            data = data.sub(l+1)
        end
        if #data > self.bufferSize then
            result, reason = self.stream:write(data)
            result = self
        else
            self.bufferWrite = self.bufferWrite .. data
            result = self
        end
    end
    return result, reason
end

function buffer:setvbuf(mode, size)
    mode = mode or self.bufferMode
    size = size or self.bufferSize
  
    assert(mode == "no" or mode == "full" or mode == "line",
      "bad argument #1 (no, full or line expected, got " .. tostring(mode) .. ")")
    assert(mode == "no" or type(size) == "number",
      "bad argument #2 (number expected, got " .. type(size) .. ")")
  
    self.bufferMode = mode
    self.bufferSize = size
  
    return self.bufferMode, self.bufferSize
  end

function buffer:write(...)
    if self.closed then
        return nil, "Buffer already closed"
    end 
    if not self.mode.w and not self.mode.a then
        return nil, "Buffer not opened for Writing"
    end
    local args = table.pack(...)
    for i = 1, args.n do
        if type(args[i]) == "number" then
            args[i] = tostring(args[i])
        end
        checkArg(i, args[i], "string")
    end

    for i = 1, args.n do
        local arg = args[i]
        local result, reason

        if self.bufferMode == "no" then
            result, reason = self.stream:write(arg)
        else
            result, reason = buffer.buffered_write(self, arg)
        end
        if not result then
            return nil, reason
        end
    end
    return self
end