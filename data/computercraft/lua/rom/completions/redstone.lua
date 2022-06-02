local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("redstone", completion.build(
  { completion.choice, {"probe", "set", "pulse"}, true },
  completion.side
))
