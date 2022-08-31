_G.io = require("rc.io")

function _G.print(...)
  local args = table.pack(...)

  for i=1, args.n, 1 do
    args[i] = tostring(args[i])
  end

  io.stdout:write(table.concat(args, "\t"), "\n")

  return true
end
