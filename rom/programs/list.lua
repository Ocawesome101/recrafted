-- list

local dir = ...

local fs = require("fs")
local shell = require("rc")
local colors = require("colors")
local settings = require("settings")
local textutils = require("textutils")

dir = dir or shell.dir()

if not fs.exists(dir) then
  error("that directory does not exist", 0)
elseif not fs.isDir(dir) then
  error("not a directory", 0)
end

local raw_files = fs.list(dir)
local files, dirs = {}, {}

local show_hidden = settings.get("list.show_hidden")

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

textutils.tabulate(colors.green, dirs, colors.white, files)
