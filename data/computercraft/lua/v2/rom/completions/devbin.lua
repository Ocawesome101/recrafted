local shell = require("shell")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("devbin", completion.build(
  { completion.choice, { "put", "get", "run" }, true },
  function(cur, prev)
    if prev[1] == "put" then
      return completion.dirOrFile(cur, prev)
    end
  end
))
