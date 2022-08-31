-- threads

local colors = require("colors")
local thread = require("rc.thread")
local strings = require("cc.strings")
local textutils = require("textutils")

textutils.coloredPrint(colors.yellow, "id   tab  name", colors.white)

local info = thread.info()
for i=1, #info, 1 do
  local inf = info[i]
  textutils.pagedPrint(string.format("%s %s %s",
    strings.ensure_width(tostring(inf.id), 4),
    strings.ensure_width(tostring(inf.tab), 4), inf.name))
end
