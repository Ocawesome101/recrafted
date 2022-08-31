local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("copy", completion.build(
  {completion.dirOrFile, true},
  {completion.dirOrFile, many = true}
))
