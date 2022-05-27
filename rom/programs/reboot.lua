local term = require("term")
local colors = require("colors")

term.setTextColor(colors.yellow)
print("Restarting")

os.sleep(1)

os.reboot()
