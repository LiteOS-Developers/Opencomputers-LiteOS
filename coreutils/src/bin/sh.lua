return {
    main = function(...)
        printf("sh.lua %s\n", dump(table.pack(...)))
        return true
    end
}