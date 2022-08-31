-- rc.commands

local expect = require("cc.expect").expect

if not package.loaded.commands then return end

local native = package.loaded.commands
local c = {}
package.loaded.commands = c

c.native = native
c.async = {}

for k, v in pairs(native) do c[k] = v end

local command_list = native.list()

for i=1, #command_list, 1 do
  local command = command_list[i]
  c.async[command] = function(...)
    return c.execAsync(command, ...)
  end
  c[command] = c[command] or function(...)
    return c.exec(command, ...)
  end
end

function c.exec(command, ...)
  expect(1, command, "string")
  return c.native.exec(table.concat(table.pack(command, ...), " "))
end

function c.execAsync(command, ...)
  expect(1, command, "string")
  return c.native.execAsync(table.concat(table.pack(command, ...), " "))
end
