-- alias

local args = {...}

local shell = require("shell")
local colors = require("colors")
local textutils = require("textutils")

if #args == 0 then
  textutils.coloredPrint(colors.yellow, "shell aliases", colors.white)

  local aliases = shell.aliases()

  local _aliases = {}
  for k, v in pairs(aliases) do
    table.insert(_aliases, {colors.cyan, k, colors.white, ":", v})
  end

  textutils.pagedTabulate(_aliases)

elseif #args == 1 then
  shell.clearAlias(args[1])

elseif #args == 2 then
  shell.setAlias(args[1], args[2])

else
  error("this program takes a maximum of two arguments", 0)
end
