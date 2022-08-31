local help = require("help")
local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("help", completion.build(
  {help.completeTopic, many = true}
))
