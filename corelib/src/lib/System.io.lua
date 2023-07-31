local api = {}
local fs = require("Service").getService("filesystem")

api.getFileContent = function(path)
    local file = fs.open(path, "r")
    local data = ""
    local content
    repeat
        content = fs.read(file, math.huge)
        data = data .. (content or "")
    until not content
    fs.close(file)
    return data
end

return api