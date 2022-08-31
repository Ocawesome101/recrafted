local term = require("term")
local colors = require("colors")
local peripheral = require("peripheral")

term.setTextColor(colors.yellow)
print("attached peripherals")
term.setTextColor(colors.white)
local names = peripheral.getNames()

if #names == 0 then
  io.stderr:write("none\n")
else
  for i=1, #names, 1 do
    print(string.format("%s (%s)", names[i], peripheral.getType(names[i])))
  end
end
