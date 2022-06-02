local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("paint", completion.build(
  
))
