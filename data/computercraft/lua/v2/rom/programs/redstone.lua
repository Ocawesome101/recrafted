local rc = require("rc")
local rs = require("redstone")
local colors = require("colors")
local textutils = require("textutils")

local args = {...}

local commands = {}

local sides = {"top", "bottom", "left", "right", "front", "back"}

function commands.probe()
  textutils.coloredPrint(colors.yellow, "redstone inputs", colors.white)
  local inputs = {}
  for i=1, #sides, 1 do
    if rs.getInput(sides[i]) then
      inputs[#inputs+1] = sides[i]
    end
  end
  if #inputs == 0 then inputs[1] = "None" end
  print(table.concat(inputs, ", "))
  return true
end

local function coerce(value)
  if value == "true" then return true end
  if value == "false" then return false end
  return tonumber(value) or value
end

function commands.set(side, color, value)
  if not side then
    io.stderr:write("side expected\n")
    return true
  end

  if not value then
    value = color
    color = nil
  end

  value = coerce(value)
  if type(value) == "string" then
    io.stderr:write("value must be boolean or 0-15\n")
  end

  if color then
    color = coerce(color)
    if type(value) == "number" then
      io.stderr:write("value must be boolean\n")
    end

    if not colors[color] then
      io.stderr:write("color not defined\n")
    end

    rs.setBundledOutput(side, colors[color], value)

  elseif type(value) == "boolean" then
    rs.setOutput(side, value)

  else
    rs.setAnalogOutput(side, value)
  end

  return true
end

function commands.pulse(side, count, period)
  count = tonumber(count) or 1
  period = tonumber(period) or 0.5

  for _=1, count, 1 do
    rs.setOutput(side, true)
    rc.sleep(period / 2)
    rs.setOutput(side, false)
    rc.sleep(period / 2)
  end

  return true
end

if not (args[1] and commands[args[1]] and
    commands[args[1]](table.unpack(args, 2))) then
  io.stderr:write("Usages:\nredstone probe\n"..
    "redstone set <side> <value>\nredstone set <side> <color> <value>\n"..
    "redstone pulse <side> <count> <period>\n")
end
