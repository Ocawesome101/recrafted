local rc = require("rc")
local term = require("term")
local colors = require("colors")

term.setTextColor(colors.yellow)
print("Shutting down")

if (...) ~= "now" then rc.sleep(1) end

rc.shutdown()
