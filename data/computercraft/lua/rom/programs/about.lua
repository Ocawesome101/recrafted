-- about

local term = require("term")
local colors = require("colors")
local textutils = require("textutils")

textutils.coloredPrint(colors.yellow, os.version() .. " on " .. _HOST,
  term.getTextColor())
