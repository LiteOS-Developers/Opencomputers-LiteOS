local stdio = {}

stdio.syscall = function(call, ...)
  return table.unpack(table.pack(coroutine.yield(call, ...)))
end

stdio.println = function(format, ...)
  format = string.format(format, ...)
  stdio.syscall("write", 1, format)
  return string.len(format)
end
