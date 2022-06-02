local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("list", completion.build(
  {completion.dir, many = true}
))
