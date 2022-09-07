-- Recrafted 1.5.0

local fs = rawget(_G, "fs")

_G._RC_ROM_DIR = _RC_ROM_DIR or (...) and fs.exists("/rc") and "/rc" or "/rom"

if fs.exists("/.start_rc.lua") and not (...) then
  _G._RC_USED_START = true
  local handle = assert(fs.open("/.start_rc.lua", "r"))
  local data = handle.readAll()
  handle.close()

  local _sd = rawget(os, "shutdown")
  local ld = rawget(_G, "loadstring") or load
  assert(ld(data, "=start_rc"))(true)
  _sd()
  while true do coroutine.yield() end
end

local function pull(tab, key)
  local func = tab[key]
  tab[key] = nil
  return func
end

-- this is overwritten further down but `load` needs it
local expect = function(_, _, _, _) end

local shutdown = pull(os, "shutdown")
local reboot = pull(os, "reboot")

-- `os` extras go in here now.
local rc = {
  _NAME = "Recrafted",
  _VERSION = {
    major = 1,
    minor = 5,
    patch = 0
  },
  queueEvent  = pull(os, "queueEvent"),
  startTimer  = pull(os, "startTimer"),
  cancelTimer = pull(os, "cancelTimer"),
  setAlarm    = pull(os, "setAlarm"),
  cancelAlarm = pull(os, "cancelAlarm"),
  getComputerID     = pull(os, "getComputerID"),
  computerID        = pull(os, "computerID"),
  getComputerLabel  = pull(os, "getComputerLabel"),
  computerLabel     = pull(os, "computerLabel"),
  setComputerLabel  = pull(os, "setComputerLabel"),
  clock       = pull(os, "clock"),
  day         = pull(os, "day"),
  epoch       = pull(os, "epoch"),
}

-- and a few more
rc.pushEvent = rc.queueEvent

function rc.shutdown()
  shutdown()
  while true do coroutine.yield() end
end

function rc.reboot()
  reboot()
  while true do coroutine.yield() end
end

local timer_filter = {}
function rc.pullEventRaw(filter)
  expect(1, filter, "string", "nil")

  local sig
  repeat
    sig = table.pack(coroutine.yield())
  until ((sig[1] == "timer" and
    timer_filter[sig[2]] == require("rc.thread").id()) or sig[1] ~= "timer")
    and (not filter) or (sig[1] == filter)

  return table.unpack(sig, 1, sig.n)
end

function rc.pullEvent(filter)
  expect(1, filter, "string", "nil")

  local sig
  repeat
    sig = table.pack(coroutine.yield())
    if sig[1] == "terminate" then
      error("terminated", 0)
    end
  until ((sig[1] == "timer" and
    timer_filter[sig[2]] == require("rc.thread").id()) or sig[1] ~= "timer")
    and (not filter) or (sig[1] == filter)

  return table.unpack(sig, 1, sig.n)
end

function rc.sleep(time, no_term)
  local id = rc.startTimer(time)
  local thread = require("rc.thread").id()
  timer_filter[id] = thread

  repeat
    local _, tid = (no_term and rc.pullEventRaw or rc.pullEvent)("timer")
  until tid == id
end

function rc.version()
  return string.format("Recrafted %d.%d.%d",
    rc._VERSION.major, rc._VERSION.minor, rc._VERSION.patch)
end

-- Lua 5.1?  meh
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

function _G.dofile(file)
  return assert(loadfile(file))()
end

for i=1, #files, 1 do
  local file = startup .. "/" .. files[i]
  assert(loadfile(file))(rc)
end

expect = require("cc.expect").expect

local thread = require("rc.thread")

thread.start()
