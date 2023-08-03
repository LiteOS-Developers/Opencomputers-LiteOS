return {
    main = function(args)
        print(">>> ")
        print(io.stdin:read("l"))
        -- while true do coroutine.yield() end
        return 0
    end
}