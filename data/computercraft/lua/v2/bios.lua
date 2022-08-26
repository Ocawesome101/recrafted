-- Recrafted v1.1

_G._RC_ROM_DIR = _RC_ROM_DIR or "/rom"

local function pull(tab, key)
  local func = tab[key]
  tab[key] = nil
  return func
end

-- this is overwritten further down but `load` needs it
local expect = function(_, _, _, _) end

-- `os` extras go in here now.
local rc = {
  _NAME = "Recrafted",
  _VERSION = {
    major = 1,
    minor = 1,
    patch = 0
  },
  queueEvent  = pull(os, "queueEvent"),
  startTimer  = pull(os, "startTimer"),
  cancelTimer = pull(os, "cancelTimer"),
  setAlarm    = pull(os, "setAlarm"),
  cancelAlarm = pull(os, "cancelAlarm"),
  shutdown    = pull(os, "shutdown"),
  reboot      = pull(os, "reboot"),
  getComputerID     = pull(os, "getComputerID"),
  computerID        = pull(os, "computerID"),
  getComputerLabel  = pull(os, "getComputerLabel"),
  computerLabel     = pull(os, "computerLabel"),
  setComputerLabel  = pull(os, "setComputerLabel"),
  clock       = pull(os, "clock"),
  day         = pull(os, "day"),
  epoch       = pull(os, "epoch"),
}

-- Lua 5.1?  More like Lua Bad.Version amirite?
if _VERSION == "Lua 5.1" then
  local old_load = load

  rc.lua51 = {
    loadstring = pull(_G, "loadstring"),
    setfenv = pull(_G, "setfenv"),
    getfenv = pull(_G, "getfenv"),
    unpack = pull(_G, "unpack"),
    log10 = pull(math, "log10"),
    maxn = pull(table, "maxn")
  }

  table.unpack = rc.lua51.unpack

  function _G.load(x, name, mode, env)
    expect(1, x, "string", "function")
    expect(2, name, "string", "nil")
    expect(3, mode, "string", "nil")
    expect(4, env, "table", "nil")

    env = env or _G

    local result, err
    if type(x) == "string" then
      result, err = rc.lua51.loadstring(x, name)
    else
      result, err = old_load(x, name)
    end

    if result then
      env._ENV = env
      rc.lua51.setfenv(result, env)
    end

    return result, err
  end

  -- Lua 5.1's xpcall sucks
  local old_xpcall = xpcall
  function _G.xpcall(call, func, ...)
    local args = table.pack(...)
    return old_xpcall(function()
      return call(table.unpack(args, 1, args.n))
    end, func)
  end
end

local fs = rawget(_G, "fs")
local startup = _RC_ROM_DIR .. "/startup"
local files = fs.list(startup)
table.sort(files)

function _G.loadfile(file)
  local handle, err = fs.open(file, "r")
  if not handle then
    return nil, err
  end

  local data = handle.readAll()
  handle.close()

  return load(data, "="..file, "t", _G)
end

for i=1, #files, 1 do
  local file = startup .. "/" .. files[i]
  assert(loadfile(file))(rc)
end

expect = require("cc.expect").expect

require("rc.thread").start()
