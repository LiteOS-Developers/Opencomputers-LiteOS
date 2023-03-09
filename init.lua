local eeprom = component.list("eeprom")()
local fs = component.proxy(component.invoke(eeprom, "getData"))
local content
local data = ""
local handle = fs.open("/System/bios.lua")
repeat
	content = fs.read(handle, math.huge)
	data = data .. (content or "")
until not content
fs.close(handle)
component.invoke(eeprom, "set", data)
component.invoke(eeprom, "setLabel", "LiteKernelBios")
local deadline = computer.uptime() + 5
repeat
	computer.pullSignal(5)
until computer.uptime() >= deadline
computer.shutdown(true)