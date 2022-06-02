local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("delete", completion.build(
  {completion.dirOrFile, many = true}
))
