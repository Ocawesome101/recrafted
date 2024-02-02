-- Recrafted BIOS file

-- (Most) system APIs go in here, not in _G.
-- You require `recrafted` to get access to them.
local rc = {}

if _RC_ROM_DIR then
  rc._ROM_DIR = _RC_ROM_DIR
  _G._RC_ROM_DIR = nil
else
  rc._ROM_DIR = "/rom"
end

rc.platform = {
  os = "Recrafted",
  version = "1.01",
  advanced = term.isColor(),
  command = not not commands,
  turtle = not not turtle,
  pocket = not not pocket,
  http = not not http,
}

local function rm(api)
  local tab = _G[api]
  _G[api] = nil
  return tab
end

-- remove CC-specific globals
rc.peripheral = rm("peripheral")
rc.redstone = rm("redstone")
rc.commands = rm("commands")
rc.pocket = rm("pocket")
rc.turtle = rm("turtle")
rc.http = rm("http")
rc.term = rm("term")
rc.fs = rm("fs")
rc.rs = rm("rs")

-- CraftOS-PC APIs
rc.periphemu = rm("periphemu")
rc.mounter = rm("mounter")
rc.config = rm("config")

-- CCEmuX API
rc.ccemux = rm("ccemux")

function rc.version()
  return "Recrafted 1.0"
end

rc.term.clear()
rc.term.setCursorPos(1,1)
rc.term.write("Starting "..rc.version()..".")
rc.term.setCursorPos(1,2)

-- this is overwritten later
rc.expect = function(_,_,_,_) end

function rc.write(text)
  rc.expect(1, text, "string")

  local lines = 0
  local w, h = rc.term.getSize()

  local function inc_cy(cy)
    lines = lines + 1

    if cy > h - 1 then
      rc.term.scroll(1)
      return cy
    else
      return cy + 1
    end
  end

  while #text > 0 do
    local nl = text:find("\n") or #text
    local chunk = text:sub(1, nl)
    text = text:sub(#chunk + 1)

    local has_nl = chunk:sub(-1) == "\n"
    if has_nl then chunk = chunk:sub(1, -2) end

    local cx, cy = rc.term.getCursorPos()
    while #chunk > 0 do
      if cx > w then
        rc.term.setCursorPos(1, inc_cy(cy))
        cx, cy = rc.term.getCursorPos()
      end

      local to_write = chunk:sub(1, w - cx + 1)
      rc.term.write(to_write)

      chunk = chunk:sub(#to_write + 1)
      cx, cy = rc.term.getCursorPos()
    end

    if has_nl then
      rc.term.setCursorPos(1, inc_cy(cy))
    end
  end

  return lines
end

-- print() gets to be global.
function _G.print(...)
  local args = table.pack(...)

  for i=1, args.n, 1 do
    args[i] = tostring(args[i])
  end

  return rc.write(table.concat(args, "  ") .. "\n")
end

local red = 0x4000
function rc.printError(...)
  local old = rc.term.getTextColor()
  rc.term.setTextColor(red)
  print(...)
  rc.term.setTextColor(old)
end

local _sd = os.shutdown
function os.shutdown()
  _sd()
  while true do coroutine.yield() end
end

-- get rid of Lua 5.1 things.
if _VERSION == "Lua 5.1" then
  local old_load = rm("load")
  rc.lua51 = {
    loadstring = rm("loadstring"),
    setfenv = rm("setfenv"),
    getfenv = rm("getfenv"),
    unpack = rm("unpack"),
    log10 = math.log10,
    maxn = table.maxn
  }

  math.log10 = nil
  table.maxn = nil

  function _G.load(x, name, mode, env)
    rc.expect(1, x, "string", "function")
    rc.expect(2, name, "string", "nil")
    rc.expect(3, mode, "string", "nil")
    rc.expect(4, env, "table", "nil")
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

  local old_xpcall = xpcall
  function _G.xpcall(call, func, ...)
    local args = table.pack(...)
    return old_xpcall(function()
      return call(table.unpack(args, 1, args.n))
    end, func)
  end
end

function _G.loadfile(file, mode, env)
  rc.expect(1, file, "string")
  rc.expect(2, mode, "string", "nil")
  rc.expect(3, env, "table", "nil")

  local handle, err = rc.fs.open(file, "r")
  if not handle then
    return nil, err
  end

  local data = handle.readAll()
  handle.close()

  return load(data, "="..file, mode, env)
end

local function _assert(a, ...)
  if not a then
    error(..., 3)
  else
    return a, ...
  end
end

function _G.dofile(file)
  return _assert(loadfile(file))()
end

-- Load debugger API
if debugger then
  local nativeWaitForBreak = debugger.waitForBreak
  function debugger.waitForBreak()
    nativeWaitForBreak()
    local ev = os.pullEventRaw()
    while ev ~= "debugger_break" do
      ev = os.pullEventRaw()
      if ev == "terminate" then
        debugger.step()
        debugger.unblock()
      end
    end
    debugger.confirmBreak()
  end
  debugger.waitForBreakAsync = nativeWaitForBreak
end

print("Loading initialization scripts.")

local files = rc.fs.list(rc._ROM_DIR.."/init")
table.sort(files)

for _, file in ipairs(files) do
  print(file)
  assert(loadfile(rc._ROM_DIR.."/init/"..file))(rc)
end

local thread = require("thread")

thread.add(function()
  local sh = require("shell")
  sh.init()
  rc.term.at(1,1).clear()

  local ok, err
  if debugger then
    require("multishell").launch(nil, "debug/startup.lua")
    ok = true
  else
    ok, err = sh.run(nil, "debug/releasenotes.lua")
  end
  if not ok then
    rc.printError(err)
    rc.sleep(1)
  end
end)

print("Starting coroutine manager.")

rc.queueEvent("init")
thread.start()