local uuid = require("uuid")
return {
    main=function(args)
        shell:print(uuid.next())
        shell:print(uuid.next())
    end
}