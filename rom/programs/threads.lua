-- threads

local term = require("term")
local colors = require("colors")
local thread = require("thread")
local strings = require("cc.strings")
local textutils = require("textutils")

term.setTextColor(colors.yellow)
print("id   name")
term.setTextColor(colors.white)

local info = thread.info()
for i=1, #info, 1 do
  local inf = info[i]
  textutils.pagedPrint(string.format("%s %s",
    strings.ensure_width(tostring(inf.id), 4), inf.name))
end
