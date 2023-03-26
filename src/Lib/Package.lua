local package = {}
package.loaded = {}
package.searchPaths = {}

package.addLibraryPath = function(path)
    checkArg(1, path, "string")
    table.insert(package.searchPaths, path)
end

package.require = function(name)
    if name:sub(1, 1) == "/" then
        local res, e = dofile(name)
        if not res then return nil, e end
        package.loaded[name] = res
        return package.loaded[name]
    end
    if package.loaded[name] ~= nil then
        return api.loaded[name]
    end
    for _, v in pairs(package.searchPaths) do
        local rPath = v:gsub("?", name)
        if filesystem.isFile(rPath) then
            local res, e = dofile(rPath)
            if not res then return nil, e end
            package.loaded[name] = res
            return package.loaded[name]
        end
    end
    return nil, "Package '".. name .. "' not found"
end

package.addLibraryPath("/Lib/?.lua")
package.addLibraryPath("/Lib/?/init.lua")
package.addLibraryPath("/Lib/?/?.lua")

return package