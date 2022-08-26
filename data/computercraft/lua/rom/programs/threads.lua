-- threads

local colors = require("colors")
local thread = require("thread")
local strings = require("cc.strings")
local textutils = require("textutils")

textutils.coloredPrint(colors.yellow, "id   group  name", colors.white)

local info = thread.info()
for i=1, #info, 1 do
  local inf = info[i]
  textutils.pagedPrint(string.format("%s %s %s",
    strings.ensure_width(tostring(inf.id), 4),
    strings.ensure_width(tostring(inf.group), 6), inf.name))
end
