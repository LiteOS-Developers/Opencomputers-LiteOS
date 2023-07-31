do
    _G.lib = {}
    local addr, invoke = computer.getBootAddress(), component.invoke
    
    _G.lib.loadfile = function(file)
        local handle = assert(invoke(addr, "open", file))
        local buffer = ""
        repeat
            local data = invoke(addr, "read", handle, math.huge)
            buffer = buffer .. (data or "")
        until not data
        invoke(addr, "close", handle)
        return load(buffer, "=" .. file, "bt", _G)
    end

    local kernel, err = _G.lib.loadfile("/boot/kernel.lua")
    if kernel == nil then
        error("Cannot load kernel: " .. err)
    end
    kernel()
end