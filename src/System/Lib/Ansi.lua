

return {
    translate = function(line)
        if #line == 0 then return end
        while #line > 0 do
            local nesc = line:find("\27", nil, true)
            local e = (nesc and nesc - 1) or #line
            local chunk = line:sub(1, e)

            line = line:sub(#chunk + 1)
            if #chunk > 0 then io.stdout:write(chunk) end
            if nesc then
                local css, params, csc, len = line:match("^\27(.)([%d;]*)([%a%d`])()")
                if css and params and csc and len then
                    -- k.write(dump({css,params,css,len}))
                    line = line:sub(len)
                    local args = {}
                    local num = ""
                    local plen = #params

                    for pos, c in params:gmatch("()(.)") do
                        if c == ";" then
                            args[#args+1] = tonumber(num) or 0
                            num = ""
            
                        elseif tonumber(c) then
                            num = num .. c
                
                            if pos == plen then
                                args[#args+1] = tonumber(num) or 0
                            end
                        end
                    end
                    if css == "[" then
                        local func = commands[csc]
                        if func then func(self, args)
                        k.printk(k.L_INFO, "unknown terminal escape: %q", csc)
                            
                    elseif css == "]" or css == "?" then
                        local func = controllers[csc]
                        if func then func(self, args) end
            
                    elseif css == "#" then -- it is hilarious to me that this exists
                        k.gpu.fill(1, 1, self.w, self.h, "E")
            
                    else
                        local func = nocsi[css]
                        if func then func(self, args) end
                    end
            
                end
            end
        end
    end
}