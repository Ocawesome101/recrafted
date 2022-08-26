local term = require("term")
local colors = require("colors")

term.setTextColor(colors.yellow)
print("Shutting down")

if (...) ~= "now" then os.sleep(1) end

os.shutdown()
