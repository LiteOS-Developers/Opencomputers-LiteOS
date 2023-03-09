
return {
    features = {
        "FEAT_FILESYSTEM",
        "FEAT_PATH_VARIABLE",
        "FEAT_EXISITING_SHELL"
    },
    main = function(args)
        if #args >= 2 then
            shell:print(shell:resolve(args[2]))
            return 0
        else

            shell:print("Missing Argument: \n  Usage: where <file>")
            return 1
        end
    end
}