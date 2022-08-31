local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("edit", completion.build(
  completion.dirOrFile
))
