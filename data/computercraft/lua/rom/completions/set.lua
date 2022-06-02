local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("set", completion.build(
  { completion.setting, true }
))
