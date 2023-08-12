return {
    main = function(...)
        print("hello world from getty\n")
        while true do coroutine.yield() end
    end
}