local term = require("term")
local colors = require("colors")

term.setTextColor(colors.yellow)
print("Restarting")

if (...) ~= "now" then os.sleep(1) end

os.reboot()
