-- alias

local args = {...}

local shell = require("shell")
local colors = require("colors")
local textutils = require("textutils")

if #args == 0 then
  textutils.coloredPrint(colors.yellow, "shell aliases\n", colors.white)

  local aliases = shell.aliases()

  local _aliases = {}
  for k, v in pairs(aliases) do
    table.insert(_aliases, {colors.cyan, k, colors.white, ":", v})
  end

  textutils.pagedTabulate(_aliases)
end
