return {
    translate = function(line)
        if #line == 0 then return end
        while #line > 0 do
            local nesc = line:find("\27", nil, true)
            local e = (nesc and nesc - 1) or #line
            local chunk = line:sub(1, e)

            line = line:sub(#chunk + 1)
            if #chunk > 0 then writelines(self, chunk) end

        end
    end
}