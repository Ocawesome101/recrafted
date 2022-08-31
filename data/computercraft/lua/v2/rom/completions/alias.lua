local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("alias", completion.build(
  nil, completion.program
))
