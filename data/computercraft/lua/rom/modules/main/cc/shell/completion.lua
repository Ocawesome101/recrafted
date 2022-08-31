-- cc.shell.completion
-- XXX incompatible: functions do not accept a 'shell' argument

local completion = require("cc.completion")
local expect = require("cc.expect").expect
local shell = require("shell")
local fs = require("fs")

local c = {}

function c.file(text)
  expect(1, text, "string")
  return fs.complete(text, shell.dir(), true, false)
end

function c.dir(text)
  expect(1, text, "string")
  return fs.complete(text, shell.dir(), false)
end

function c.dirOrFile(text, previous, add_space)
  expect(1, text, "string")
  expect(2, previous, "table")
  expect(3, add_space, "boolean", "nil")
  local completed = fs.complete(text, shell.dir(), true, true)

  if add_space then
    for i=1, #completed, 1 do
      completed[i] = completed[i] .. " "
    end
  end

  return completed
end

function c.program(text, add_space)
  expect(1, text, "string")
  expect(2, add_space, "boolean", "table", "nil")
  local progs = shell.programs()
  local files = c.file(text)

  local seen = {}
  for i=1, #files, 1 do
    local full = text..files[i]
    if fs.isDir(full) and full:sub(-1) ~= "/" then
      full = full .. "/"
    end
    if not seen[full] then
      progs[#progs+1] = full
    end
    seen[full] = true
  end

  table.sort(progs, function(a,b) return #a < #b end)

  return completion.choice(text, progs, add_space)
end

function c.programWithArgs(text, previous, starting)
  expect(1, text, "string")
  expect(2, previous, "table")
  expect(3, starting, "number")

  if not previous[starting] then
    return shell.completeProgram(text)
  end

  local command = previous[starting]
  command = shell.aliases()[command] or command
  local complete = shell.getCompletionInfo()[command]

  if complete then
    return complete(#previous - starting + 1, text,
      {table.unpack(previous, starting)})
  end
end

for k,v in pairs(completion) do
  c[k] = function(text, _, ...) return v(text, ...) end
end

function c.build(...)
  local args = table.pack(...)

  for i=1, args.n, 1 do
    expect(i, args[i], "function", "table", "nil")
  end

  return function(index, current, previous)
    local complete
    if args.n < index then
      if type(args[args.n]) == "table" and args[args.n].many then
        complete = args[args.n]
      end

    else
      complete = args[index]
    end

    if not complete then
      return {}
    end

    if type(complete) == "function" then
      return complete(current, previous)

    elseif type(complete) == "table" then
      return complete[1](current, previous, table.unpack(complete, 2))
    end
  end
end

return c
