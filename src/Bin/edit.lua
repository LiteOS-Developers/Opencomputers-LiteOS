local gpu
local fs = filesystem

local editor = {}

editor.frame = function()

end

return {
    main = function()
        local name = args[2]
        gpu = fs.open("/dev/gpu")
        cursor = fs.open("/dev/cursor")
        w,h = ioctl(gpu, "getResolution")

        return 0
    end
}