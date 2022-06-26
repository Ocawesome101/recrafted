local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("cd", completion.build(completion.dir))
