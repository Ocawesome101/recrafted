-- list

local args = {...}

local fs = require("fs")
local shell = require("shell")
local colors = require("colors")
local settings = require("settings")
local textutils = require("textutils")

if #args == 0 then args[1] = shell.dir() end

local show_hidden = settings.get("list.show_hidden")

local function list_dir(dir)
  if not fs.exists(dir) then
    error(dir .. ": that directory does not exist", 0)
  elseif not fs.isDir(dir) then
    error(dir .. ": not a directory", 0)
  end

  local raw_files = fs.list(dir)
  local files, dirs = {}, {}

  for i=1, #raw_files, 1 do
    local full = fs.combine(dir, raw_files[i])

    if raw_files[i]:sub(1,1) ~= "." or show_hidden then
      if fs.isDir(full) then
        dirs[#dirs+1] = raw_files[i]

      else
        files[#files+1] = raw_files[i]
      end
    end
  end

  textutils.pagedTabulate(colors.green, dirs, colors.white, files)
end

for i=1, #args, 1 do
  if #args > 1 then
    textutils.coloredPrint(colors.yellow, args[i]..":\n", colors.white)
  end
  list_dir(args[i])
end
