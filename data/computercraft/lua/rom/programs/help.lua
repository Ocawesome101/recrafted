-- help

local help = require("help")
local textutils = require("textutils")

local args = {...}

if #args == 0 then
  args[1] = "help"
end

local function view(name)
  textutils.coloredPagedPrint(table.unpack(help.loadTopic(name)))
end

for i=1, #args, 1 do
  local path = help.lookup(args[i])
  if not path then
    error("No help topic for " .. args[i], 0)
  end
  view(args[i])
end
