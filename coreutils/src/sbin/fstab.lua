local function load_fstab()
    local fstab = ""
    do
        local fd = syscall("open", "/etc/fstab", "r")
        local chunk
        repeat
            chunk = syscall("read", fd, math.huge)
            inittab = inittab .. (chunk or "")
        until not chunk
        syscall("close", fd)
    end
    local parsed = {}
    do
        local lines = split(fstab, "\n")
        for _, line in ipairs(lines) do
            local splitted = split(line, " ")
            local type = splitted[1]
            local trg = table.concat(splitted[2], " "):gsub("\r", "")
            parsed[#parsed + 1] = {
                type=type,
                trg = trg
            }
        end
    end
    return parsed
end

return {
    main = function(...)
        -- local fstab = load_fstab()
        -- printf("FSTAB: \n%s\n", dump(fstab))
        
    end
}