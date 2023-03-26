k.printk(k.L_INFO, " - 12_io")

_G.io = {}
-- local buffers = require("Buffer")
local write = k.write
local lvl = k.L_INFO
io.stdout = require("Buffer").new("w", {
    write = function(self, buf)
        -- checkArg(2, buf, "string")
        local lines = string.gmatch(buf, "([^\n]+)")
        -- string.gmatch(s, )
        local a = {}
        write("===")
        for line in lines do
            table.insert(a, line)
            write(line) -- :sub(1, line:len() - 1)
        end
        write("===")
    end
})
io.stdout:setvbuf("no")
io.stderr = require("Buffer").new("w", {
    write = function(self, buf)
        k.gpu.setForeground(0xF00000)
        for line in buf:gmatch("[^\n]") do
            k.write(line)
        end
        k.gpu.setForeground(0xFFFFFF)
    end
})

-- print = function(...)
--     io.stdout:writelines(...)
-- end

