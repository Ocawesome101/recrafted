local fs = require("fs")
local shell = require("shell")
local printError = require("printError")

local args = {...}
if #args == 0 then
  printError("usage: delete <paths>")
  return
end

for i=1, #args, 1 do
  local files = fs.find(shell.resolve(args[i]))
  if not files then
    printError("file(s) not found")
    return
  end

  for n=1, #files, 1 do
    if fs.isReadOnly(files[n]) then
      printError(files[n] .. ": cannot remove read-only file")
      return
    end
    fs.delete(files[n])
  end
end
