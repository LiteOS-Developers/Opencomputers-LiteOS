--#include "./filesystem.lua"
--#include "./io.lua"

if k.devfs then
  k.devfs.register_device("/stdout", k.io.stdout)
  k.devfs.register_device("/stdin", k.io.stdin)
  k.devfs.register_device("/stderr", k.io.stderr)
end
