local shell = require("shell")

local function lfill(str, count)
    checkArg(1, str, "string")
    checkArg(2, count, "number")
    char = " "
    local toFill = count - str:len()
    if toFill <= 0 then return str end
    repeat
        str = char .. str
    until str:len() == count
    return str
end

return {
    main = function(args)
        local cwd = shell.getcwd()
        if args[1] then
            cwd = args[1]
        end
        if not syscall("exists", cwd) or not syscall("isDirectory", cwd) then
            printf("\27[1;31m%s does not exists or is not a Directory\27[m\n", cwd)
            syscall("exit", -1)
            return
        end
        if cwd:sub(-1,-1) == "/" then cwd = cwd:sub(1, -2) end
        local files = syscall("list", cwd)
        if files == nil then
            printf("\27[1;31m%s does not support 'list' operation\n\27[m", cwd)
            syscall("exit", -1)
            return
        end
        printf("total %d\n", #files)
        for _, file in ipairs(files) do
            local path = cwd .. "/" .. file
            local stat = syscall("stat", path)
            if stat == nil then
                printf("No Stat: %s\n", path)
                goto continue
            end
            -- printf("%s %s\n", file, dump(stat))
            printf("%s %s %s %s ", umask_to_str(stat.mode), syscall("user", tostring(stat.gid)).name, syscall("group", tostring(stat.uid)).name, 
                lfill(string.format("%d", stat.size), 5, " "))
            if syscall("isDirectory", path) then
                printf("\27[1;34m%s\27[m\n", file)
            else
                printf("%s\n", file)
            end
            ::continue::
        end
    end
}