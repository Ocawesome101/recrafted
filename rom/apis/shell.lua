-- Recrafted shell api

local shell = {}

local rc = require("rc")
local fs = require("fs")

function shell.init()
  local vars = rc.vars()

  if vars.aliases then
    local old = vars.aliases
    vars.aliases = setmetatable({}, {__index = old})
  else
    vars.aliases = {}
  end

  vars.path = vars.path or string.format(
    ".:%s/programs", rc._ROM_DIR)
end

local builtins = {
  cd = function(dir)
    if dir then
      shell.setDir(dir)
    else
      print(shell.dir())
    end
  end
}

local function callCommand(command, func, ...)
  rc.vars().program = command

  local success, prog_err = pcall(func, ...)

  rc.vars().program = "shell"

  if not success then
    return nil, prog_err
  end

  return true
end

function shell.execute(command, ...)
  rc.expect(1, command, "string")

  if builtins[command] then
    local func = builtins[command]
    return callCommand(command, func, ...)
  else
    local path, res_err = shell.resolveProgram(command)
    if not path then
      return nil, res_err
    end

    local ok, err = loadfile(path)

    if not ok then
      return nil, err
    end

    local args = table.pack(...)
    local id = rc.thread.add(function()
      shell.init()
      return callCommand(command, ok, table.unpack(args, 1, args.n))
    end, command)

    repeat rc.sleep(0.05) until not rc.thread.exists(id)
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

-- difference: this exits the current thread on next yield
function shell.exit()
  rc.thread.remove(rc.thread.id())
end

function shell.dir()
  return rc.dir()
end

function shell.setDir(dir)
  rc.expect(1, dir, "string")
  return rc.setDir(shell.resolve(dir))
end

function shell.path()
  return rc.vars().path
end

function shell.setPath(path)
  rc.expect(1, path, "string")
  rc.vars().path = path
end

function shell.resolve(path)
  rc.expect(1, path, "string")

  if path:sub(1,1) == "/" then
    return path
  end

  return fs.combine(rc.dir(), path)
end

function shell.resolveProgram(path)
  rc.expect(1, path, "string")

  local aliases = rc.vars().aliases
  if aliases[path] then
    path = aliases[path]
  end

  if fs.exists(path) and not fs.isDir(path) then
    return path
  end

  for search in rc.vars().path:gmatch("[^:]+") do
    local try = fs.combine(search, path .. ".lua")
    if fs.exists(try) and not fs.isDir(try) then
      return try
    end
  end

  return nil, "command not found"
end

function shell.programs(hidden)
  rc.expect(1, hidden, "boolean", "nil")

  local programs = {}

  for search in rc.vars().path:gmatch("[^:]+") do
    local files = fs.list(search)
    for i=1, #files, 1 do
      programs[#programs+1] = files[i]:match("^(.+)%.lua$")
    end
  end

  return programs
end

function shell.complete(line)
  rc.expect(1, line, "string")
end

function shell.completeProgram(line)
  rc.expect(1, line, "string")
end

function shell.setCompletionFunction(program, complete)
  rc.expect(1, program, "string")
  rc.expect(2, complete, "function")
end

function shell.getCompletionInfo()
end

function shell.getRunningProgram()
  return rc.vars().program
end

function shell.setAlias(command, program)
  rc.expect(1, command, "string")
  rc.expect(2, program, "string")

  rc.vars().aliases[command] = program
end

function shell.clearAlias(command)
  rc.expect(1, command, "string")

  rc.vars().aliases[command] = nil
end

function shell.aliases()
  return rc.vars().aliases
end

function shell.openTab(...)
  return require("multishell").openTab(...)
end

function shell.switchTab(id)
  return require("multishell").switchTab(id)
end

return shell
