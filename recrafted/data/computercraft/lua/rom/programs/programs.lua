local shell = require("shell")
local colors = require("colors")
local textutils = require("textutils")

textutils.coloredPrint(colors.yellow, "available programs\n", colors.white)
textutils.pagedTabulate(shell.programs())
