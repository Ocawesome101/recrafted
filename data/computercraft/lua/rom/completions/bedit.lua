local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("bedit", completion.build(
  completion.dirOrFile
))
