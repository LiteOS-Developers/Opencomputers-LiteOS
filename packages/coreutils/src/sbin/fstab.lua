local function load_fstab()
    local fstab = ""
    do
        local fd = syscall("open", "/etc/fstab", "r")
        local chunk
        repeat
            chunk = syscall("read", fd, math.huge)
            fstab = fstab .. (chunk or "")
        until not chunk
        syscall("close", fd)
    end
    local parsed = {}
    do
        local lines = split(fstab, "\n")
        for _, line in ipairs(lines) do
            local splitted = split(line, " ")
            local type = splitted[1]
            local trg = table.concat(splitted, " ", 2):gsub("\r", "")
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
        local fstab = load_fstab()
        for _, entry in ipairs(fstab) do
            local success, errno = syscall("mount", entry.type, entry.trg)
            if not success then
                printf("Cannot mount %s: %d\n", entry.trg, errno or 0)
            end
        end
    end
}