local fs = require("fs")
local shell = require("shell")
local args = {...}

if #args == 0 then
  io.stderr:write("usage: mkdir <paths>\n")
  return
end

for i=1, #args, 1 do
  fs.makeDir(shell.resolve(args[i]))
end
