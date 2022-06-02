local shell = require("shell")
local complete = require("cc.completion")
local completion = require("cc.shell.completion")

shell.setCompletionFunction("redstone", completion.build(
  { completion.choice, {"probe", "set", "pulse"}, {false, true, true} },
  completion.side,
  function(cur, prev)
    if prev[1] == "set" then
      return complete.color(cur, true)
    end
  end
))
