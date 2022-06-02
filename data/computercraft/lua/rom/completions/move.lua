local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("move", completion.build(
  {completion.dirOrFile, true},
  {completion.dirOrFile, many = true}
))
