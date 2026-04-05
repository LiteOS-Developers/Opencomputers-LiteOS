local api = {}
local native = filesystem

api.open = function(path, mode)
    checkArg(1, path, "string")
    checkArg(2, mode, "string")
    local handle, e = native.open(path, mode)
    if not handle then
        error(e)
        return nil
    end
    local b = require("Buffer").new(mode, {
        write = function(self, line, a)
            native.write(handle, line)
        end,
        seek = function(self, offset, whence)
            native.seek(handle, whence, offset)
        end,
        read = function(self, count)
            return native.read(handle, count)
        end,
        close = function() 
            return native.close(handle)
        end
    })
    b:setvbuf("no")

    return b    
end

return api