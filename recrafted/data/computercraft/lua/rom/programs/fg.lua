-- fg

local args = {...}

if #args == 0 then
  error("command not provided", 0)
end

local shell = require("shell")
local multishell = require("multishell")

local path, err = shell.resolveProgram(args[1])
if not path then
  error(err, 0)
end

multishell.setFocus(multishell.launch(path, table.unpack(args, 2)))
