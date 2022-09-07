-- launch different editors based on computer capabilities

local term = require("term")
local settings = require("settings")

local df = function(f, ...) return assert(loadfile(f))(...) end

if term.isColor() or settings.get("edit.force_highlight") then
  df("/rc/editors/advanced.lua", ...)
else
  df("/rc/editors/basic.lua", ...)
end
