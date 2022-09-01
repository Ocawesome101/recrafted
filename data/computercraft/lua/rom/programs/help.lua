-- help

local help = require("help")
local textutils = require("textutils")

local args = {...}

if #args == 0 then
  args[1] = "help"
end

local function view(name)--path)
  textutils.coloredPagedPrint(table.unpack(help.loadTopic(name)))
  --local lines = {}
  --for l in io.lines(path) do lines[#lines+1] = l end
  --textutils.pagedPrint(table.concat(require("cc.strings").wrap(table.concat(lines,"\n"), require("term").getSize()), "\n"))
end

for i=1, #args, 1 do
  local path = help.lookup(args[i])
  if not path then
    error("No help topic for " .. args[i], 0)
  end
  view(args[i])--path)
end
