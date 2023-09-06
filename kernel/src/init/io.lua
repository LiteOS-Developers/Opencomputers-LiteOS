--#skip 13
--[[
    Copyright (C) 2023 thegame4craft

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

--#ifdef DRV_DEVFS
--#ifdef LIB_BUFFER
k.printk(k.L_INFO, "init/io")

k.io = {}

k.readfile = function(path)
    local data = ""
    local chk
    -- error(dump(path))
    local file, e = k.open(path, "r")

    if not file then
        return nil, e
    end
    repeat
        chk = k.read(file, math.huge)
        data = data .. (chk or "")
    until not chk
    k.close(file)
    return data
end

k.io.stdout = k.buffer.new("w", {
    write = function(self, buf)
        k.printf(buf .. "\n")
    end
})
k.io.stdout:setvbuf("no")
k.io.stderr = k.buffer.new("w", {
    write = function(self, buf)
        local old, _ = k.gpu.setForeground(0xF00000)
        k.printf(buf .. "\n")
        k.gpu.setForeground(old, _)
    end
})
k.io.stderr:setvbuf("no")

k.io.stdin = k.buffer.new("r", {
    read = function(self, count)
        local line = ""
        local x, y = k.cursor:getX(), k.cursor:getY()
        if y + 1 >= k.cursor.height then
            y = k.cursor.height - 1
        end
        while true do
            local _, addr, char, code, ply = k.event.pull("key_down")
            local chr = utf8.char(char)
            if chr == "\r" then
                k.setText(x, y, " ")
                k.cursor:move(x, y)
                k.printf("%s\n", line)
                break
            elseif chr == "\b" then
                line = line:sub(1, -2)
            elseif chr == "\t" then
                line = line .. "    "
            else
                line = line .. chr
            end
            k.setText(x, y, line)
        end
        return line
    end
})
k.io.stdin:setvbuf("no")

--#endif 
--#endif


