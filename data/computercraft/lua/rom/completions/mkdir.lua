local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("mkdir", completion.build(
  {completion.dir, many = true}
))
