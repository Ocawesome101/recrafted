local term = require("term")
local colors = require("colors")

term.setTextColor(colors.yellow)
print("Shutting down")

os.sleep(1)

os.shutdown()
