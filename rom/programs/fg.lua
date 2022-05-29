-- fg

local args = {...}

local shell = require("shell")
local multishell = require("multishell")

local path, err = shell.resolveProgram(args[1])
if not path then
  error(err, 0)
end

multishell.launch(path, table.unpack(args, 2))
