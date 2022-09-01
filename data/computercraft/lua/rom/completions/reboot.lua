local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("reboot", completion.build(
  { completion.choice, { "now" } }
))
