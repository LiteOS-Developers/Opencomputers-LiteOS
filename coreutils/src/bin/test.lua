return {
    main = function(args)
        printf(">>> ")
        printf("%s\n", io.stdin:read("l"))
        -- while true do coroutine.yield() end
        return 0
    end
}