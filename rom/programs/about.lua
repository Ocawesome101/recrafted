-- about

local term = require("term")
local colors = require("colors")

local old = term.getTextColor()
term.setTextColor(colors.yellow)

print(os.version() .. " on " .. _HOST)

term.setTextColor(old)
