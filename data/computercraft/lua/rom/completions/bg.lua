local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("bg", completion.build(
  { completion.programWithArgs, 1, many = true }
))
