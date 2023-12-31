local json = require("json")
local tar = require("tar")
local filesystem = require("filesystem")
local uuid = require("uuid")

local pm = {}

local f = string.format

function getPackageListData()
    local handle, e = syscall("open", PACKAGE_LIST)
    if handle == nil then
        if e == 2 then
            local handle, e = syscall("open", PACKAGE_LIST, "w")
            if handle == nil then
                return nil, string.format("Can't create Package List: %d", e)
            end
            syscall("write", handle, "{}")
            syscall("close", handle)
            return {}
        end
    end
    local content = ""
    local buf
    repeat
        buf = syscall("read", handle, math.huge)
        content = content .. (buf or "")
    until not buf
    syscall("close", handle)
    return content
end


function pm.getManifestFromInstalled(package)
    local file = assert(io.open(f("/etc/pm/info/%s.manifest", package)))
    ---@type manifest
    local currentManifest = serialization.unserialize(file:read("a"))
    file:close()
    return currentManifest
end

function pm.getManifestFromPackage(package)
    package = filesystem.abspath(package)
    if not filesystem.exists(package) or filesystem.isDirectory(package) then
        return false
    end

    -- create a folder for tmpPath
    local tmpPath = "/tmp/pm/"
    if not filesystem.exists(tmpPath) then
        filesystem.makeDirectory(tmpPath)
    end

    -- create folder for package
    repeat
        tmpPath = "/tmp/pm/" .. uuid.next()
    until not filesystem.isDirectory(tmpPath)
    filesystem.makeDirectory(tmpPath)

    local ok, reason = tar.extract(packagePath, tmpPath, true, "CONTROL/manifest", nil, "CONTROL/")
    local filepath = tmpPath .. "/manifest"

    local manifestFile = assert(io.open(filepath, "r"))
    local manifest, reason = json.load(manifestFile:read("*a"))
    if (not manifest) then
        return nil, f("Invalid package manifest. Could not parse"), reason
    end
    filesystem.remove(tmpPath)
    return manifest
end

---get the list of installed packages
---@param includeNonPurged? boolean
---@return table<string,manifest>
function pm.getInstalled(includeNonPurged)
    checkArg(1, includeNonPurged, 'boolean', 'nil')
    local prefix = "%.files$"
    if (includeNonPurged) then prefix = "%.manifest$" end
    local installed = {}
    for file in filesystem.list("/etc/pm/info/") do
        local packageName = file:match("(.+)" .. prefix)
        if (packageName) then
            installed[packageName] = pm.getManifestFromInstalled(packageName)
        end
    end
    return installed
end

function pm.isInstalled(package)
    local installed = filesystem.exists(f("/etc/pm/info/%s.files", package))
    local notPurged = filesystem.exists(f("/etc/pm/info/%s.manifest", package))
    return installed and notPurged, notPurged
end

function pm.checkDependant(package)
    printf("Checking for package dependant of %s", package)
    for pkg, manifest in pairs(pm.getInstalled(false)) do
        ---@cast pkg string
        ---@cast manifest manifest
        if (manifest.dependencies and manifest.dependencies[package]) then
            return true, pkg
        end
    end
    return false
end

function pm.getDependantOf(package)
    local dep = {}
    for installedPackageName, installedPackageManifest in pairs(pm.getInstalled(false)) do
        if (installedPackageManifest.dependencies and installedPackageManifest.dependencies[package]) then
            table.insert(dep, installedPackageName)
        end
    end
    return dep
end

return pm