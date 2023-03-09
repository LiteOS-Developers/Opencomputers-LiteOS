local api = {}
local fs = require("Service").getService("filesystem")

api.getFileContent = function(path)
    file = fs.open(path, "r")
    local data = ""
    local content
    repeat
        content = file:read(math.huge)
        data = data .. (content or "")
    until not content
    file:close()
    return data
end

return api