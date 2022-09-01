local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("shutdown", completion.build(
  { completion.choice, { "now" } }
))
