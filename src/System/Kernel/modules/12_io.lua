k.printk(k.L_INFO, " - 12_io")

_G.io = {}
-- local buffers = require("Buffer")
local write = k.write
local lvl = k.L_INFO
io.stdout = require("Buffer").new("w", {
    write = function(self, buf)
        local lines = string.gmatch(buf, "([^\n]+)")
        for line in lines do
            write(line)
        end
    end
})
io.stdout:setvbuf("no")
io.stderr = require("Buffer").new("w", {
    write = function(self, buf)
        local old, _ = k.gpu.setForeground(0xF00000)
        local lines = string.gmatch(buf, "([^\n]+)")
        for line in lines do
            write(line)
        end
        k.gpu.setForeground(old, _)
    end
})

-- print = function(...)
--     io.stdout:writelines(...)
-- end

