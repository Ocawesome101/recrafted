-- about

local rc = require("rc")
local colors = require("colors")
local textutils = require("textutils")

textutils.coloredPrint(colors.yellow, rc.version() .. " on " .. _HOST)
