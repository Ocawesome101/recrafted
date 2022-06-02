local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("bg", completion.build(
  completion.program
))
