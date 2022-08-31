local fs = require("fs")
local shell = require("shell")

local args = {...}
if #args == 0 then
  io.stderr:write("usage: delete <paths>\n")
  return
end

for i=1, #args, 1 do
  local files = fs.find(shell.resolve(args[i]))
  if not files then
    io.stderr:write("file(s) not found\n")
    return
  end

  for n=1, #files, 1 do
    if fs.isReadOnly(files[n]) then
      io.stderr:write(files[n] .. ": cannot remove read-only file\n")
      return
    end
    fs.delete(files[n])
  end
end
