local api = {}
local shell = require("Shell")

api.features = {
    "FEAT_FULL_FILESYSTEM",
    "FEAT_USER_AUTH",
}
api.main = function(grantedFeatures, args)
    if inTable(grantedFeatures, "FEAT_FULL_FILESYSTEM") ~= true then
        error("Feature FEAT_FULL_FILESYSTEM isn't granted!")
    end
    if inTable(grantedFeatures, "FEAT_USER_AUTH") ~= true then
        error("Feature FEAT_USER_AUTH isn't granted!")
    end
    local sh = shell.getTTY("tty0") 
    if sh == nil then
        sh = shell.create("/")
    end

    local result = sh:auth()
    sh:print("Logged In")
    sh:chdir(result.home)
    sh:setenv("PATH", "/Bin:/Users/Bin")
    local command, cmd, pwd, path, args, exitCode
    local host = result.username .. "@" .. result.hostname
    while true do
        pwd = sh:getpwd()
        if string.len(pwd) == 0 then pwd = "/" end
        command = sh:read(host .. ":" .. pwd .. "# ")
        cmd = split(command, " ")[1]
        if cmd == nil then goto shellContinue end
        path = sh:resolve(cmd)
        if path == nil or not syscall("isFile", path) then
            sh:print(dump(syscall("isFile", path)))
            sh:print(cmd .. ": Command not found")
            goto shellContinue
        end
        args = split(command, " ")
        exitCode = sh:execute(path, args)
        sh:setenv("EXIT", exitCode)
        ::shellContinue::
    end
    return 0
end

return api
