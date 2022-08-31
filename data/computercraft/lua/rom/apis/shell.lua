-- Recrafted shell api

local shell = {}

local rc = require("rc")
local fs = require("fs")
local colors = require("colors")
local thread = require("rc.thread")
local expect = require("cc.expect").expect
local settings = require("settings")
local textutils = require("textutils")

local function copyIfPresent(f, t)
  if t[f] then
    local old = t[f]

    t[f] = {}
    for k, v in pairs(old) do
      t[f][k] = v
    end

  else
    t[f] = {}
  end
end

local completions = {[0]={}}

function shell.init()
  local vars = thread.vars()

  copyIfPresent("aliases", vars)
  completions[vars.parentShell or 0] = completions[vars.parentShell or 0] or {}

  vars.path = vars.path or ".:/rc/programs"
end

local builtins = {
  cd = function(dir)
    if dir then
      shell.setDir(dir)
    else
      print(shell.dir())
    end
  end,

  exit = function()
    shell.exit()
  end,

  alias = function(...)
    local args = {...}

    if #args == 0 then
      textutils.coloredPrint(colors.yellow, "shell aliases", colors.white)

      local aliases = shell.aliases()

      local _aliases = {}
      for k, v in pairs(aliases) do
        table.insert(_aliases, {colors.cyan, k, colors.white, ":", v})
      end

      textutils.pagedTabulate(_aliases)

    elseif #args == 1 then
      shell.clearAlias(args[1])

    elseif #args == 2 then
      shell.setAlias(args[1], args[2])

    else
      error("this program takes a maximum of two arguments", 0)
    end
  end
}

local function callCommand(command, func, ...)
  thread.vars().program = command

  local success, prog_err
  if settings.get("shell.tracebacks") then
    success, prog_err = xpcall(func, debug.traceback, ...)
  else
    success, prog_err = pcall(func, ...)
  end

  thread.vars().program = "shell"

  if not success then
    return nil, prog_err
  end

  return true
end

local function execProgram(fork, command, ...)
  local path, res_err = shell.resolveProgram(command)
  if not path then
    return nil, res_err
  end

  local ok, err = loadfile(path)

  if not ok then
    return nil, err
  end

  if fork then
    local args = table.pack(...)
    local result
    local id = thread.spawn(function()
      shell.init()
      result = table.pack(callCommand(path, ok,
        table.unpack(args, 1, args.n)))
    end, command)

    repeat rc.sleep(0.05, true) until not thread.exists(id)

    if result then
      return table.unpack(result, 1, result.n)
    end

    return true

  else
    return callCommand(path, ok, ...)
  end
end

-- execute a command, but do NOT fork
function shell.exec(command, ...)
  expect(1, command, "string")
  return execProgram(false, command, ...)
end

function shell.execute(command, ...)
  expect(1, command, "string")

  if builtins[command] then
    local func = builtins[command]
    return callCommand(command, func, ...)

  else
    return execProgram(true, command, ...)
  end

  return true
end

local function tokenize(str)
  local words = {}
  for word in str:gmatch("[^ ]+") do
    words[#words+1] = word
  end
  return words
end

function shell.run(...)
  return shell.execute(table.unpack(tokenize(table.concat({...}, " "))))
end

-- difference: this exits the current thread immediately
function shell.exit()
  thread.remove()
end

function shell.dir()
  return thread.dir()
end

function shell.setDir(dir)
  expect(1, dir, "string")
  return thread.setDir(shell.resolve(dir))
end

function shell.path()
  return thread.vars().path
end

function shell.setPath(path)
  expect(1, path, "string")
  thread.vars().path = path
end

function shell.resolve(path)
  expect(1, path, "string")

  if path:sub(1,1) == "/" then
    return path
  end

  return fs.combine(thread.dir(), path)
end

function shell.resolveProgram(path)
  expect(1, path, "string")

  local aliases = thread.vars().aliases
  if aliases[path] then
    path = aliases[path]
  end

  if fs.exists(path) and not fs.isDir(path) then
    return path
  end

  for search in thread.vars().path:gmatch("[^:]+") do
    if search == "." then search = shell.dir() end
    local try1 = fs.combine(search, path)
    local try2 = fs.combine(search, path .. ".lua")
    if fs.exists(try1) and not fs.isDir(try1) then
      return try1
    end
    if fs.exists(try2) and not fs.isDir(try2) then
      return try2
    end
  end

  return nil, "command not found"
end

function shell.programs(hidden)
  expect(1, hidden, "boolean", "nil")

  local programs = {}

  local seen = {}
  for search in thread.vars().path:gmatch("[^:]+") do
    local files = fs.list(shell.resolve(search))
    for i=1, #files, 1 do
      programs[#programs+1] = files[i]:match("^(.+)%.lua$")
      if programs[#programs] then
        seen[programs[#programs]] = true
      end
    end
  end

  for alias in pairs(shell.aliases()) do
    if not seen[alias] then programs[#programs+1] = alias end
  end

  for builtin in pairs(builtins) do
    if not seen[builtin] then programs[#programs+1] = builtin end
  end

  return programs
end

function shell.complete(line)
  expect(1, line, "string")

  local words = tokenize(line)
  local aliases = thread.vars().aliases or {}

  if #words > (line:sub(-1) == " " and 0 or 1) then
    words[1] = aliases[words[1]] or words[1]
  end

  if line:sub(-1) == " " and #words > 0 then
    local complete = completions[thread.vars().parentShell or 0][words[1]]
    if complete then
      table.remove(words, 1)
      return complete(#words + 1, "", words)
    end
  else
    if #words == 1 then
      local opt = shell.completeProgram(words[1])

      for i=1, #opt, 1 do
        if shell.resolveProgram(words[1] .. opt[i]) then
          opt[i] = opt[i] .. " "
        end
      end

      return opt

    else
      local complete = completions[thread.vars().parentShell or 0][words[1]]
      if complete then
        local arg = table.remove(words, #words)
        table.remove(words, 1)
        return complete(#words + 1, arg, words)
      end
    end
  end
end

function shell.completeProgram(line)
  expect(1, line, "string")
  return require("cc.shell.completion").program(line)
end

function shell.setCompletionFunction(program, complete)
  expect(1, program, "string")
  expect(2, complete, "function")
  completions[thread.vars().parentShell or 0][program] = complete
end

function shell.getCompletionInfo()
  return completions[thread.vars().parentShell or 0]
end

function shell.getRunningProgram()
  return thread.vars().program
end

function shell.setAlias(command, program)
  expect(1, command, "string")
  expect(2, program, "string")

  thread.vars().aliases[command] = program
end

function shell.clearAlias(command)
  expect(1, command, "string")

  thread.vars().aliases[command] = nil
end

function shell.aliases()
  return thread.vars().aliases
end

function shell.openTab(...)
  return require("multishell").launch(...)
end

function shell.switchTab(id)
  return require("multishell").setFocus(id)
end

return shell
