local fs = require("fs")
local shell = require("shell")

local args = {...}

if #args < 2 then
  io.stderr:write("usage: copy <source> <destination>\n")
  return
end

local source, destination = shell.resolve(args[1]), shell.resolve(args[2])
local files = fs.find(source)

if #files > 0 then
  local dir = fs.isDir(destination)

  if #files > 1 and not dir then
    io.stderr:write("destination must be a directory\n")
    return
  end

  for i=1, #files, 1 do
    if dir then
      fs.copy(files[i], fs.combine(destination, fs.getName(files[i])))
    elseif #files == 1 then
      if fs.exists(destination) then
        io.stderr:write("file already exists\n")
        return
      else
        fs.copy(files[i], destination)
      end
    end
  end
else
  io.stderr:write("no such file(s)\n")
end
