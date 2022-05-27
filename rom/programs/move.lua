local fs = require("fs")
local shell = require("shell")
local printError = require("printError")

local args = {...}

if #args < 2 then
  printError("usage: move <source> <destination>")
  return
end

local source, destination = shell.resolve(args[1]), shell.resolve(args[2])
local files = fs.find(source)

if #files > 0 then
  local dir = fs.isDir(destination)

  if #files > 1 and not dir then
    printError("destination must be a directory")
    return
  end

  for i=1, #files, 1 do
    if dir then
      fs.move(files[i], fs.combine(destination, fs.getName(files[i])))
    elseif #files == 1 then
      if fs.exists(destination) then
        printError("file already exists")
        return
      else
        fs.move(files[i], destination)
      end
    end
  end
else
  printError("no such file(s)")
end
