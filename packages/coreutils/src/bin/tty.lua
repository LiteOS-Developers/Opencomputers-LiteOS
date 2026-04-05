return {
  main = function()
    local proc = syscall("pstat", syscall("getpid"))
    if #table.keys(proc) == 0 or proc.shell == nil then
      printf("tty: No tty defined\n")
      return -100
    end
    printf(proc.shell .. "\n")
  end
}
