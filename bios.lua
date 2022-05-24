-- Recrafted BIOS file

-- (Most) system APIs go in here, not in _G.
-- You require `recrafted` to get access to them.
local rc = {}

rc._ROM_DIR = "/rom"

local function rm(api)
  local tab = _G[api]
  _G[api] = nil
  return tab
end

-- remove CC-specific globals
rc.peripheral = rm("peripheral")
rc.redstone = rm("redstone")
rc.turtle = rm("turtle")
rc.http = rm("http")
rc.term = rm("term")
rc.fs = rm("fs")
rc.rs = rm("rs")

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
  while #text > 0 do
    local cx, cy = rc.term.getCursorPos()

    local next_bit = text:sub(1, math.min(w - cx, text:find("\n") or 0))
    text = text:sub(#next_bit+1)

    if #next_bit > 0 then lines = lines + 1 end
    rc.term.write(next_bit)

    if cy == h and #text > 0 then
      rc.term.scroll(1)
    else
      rc.term.setCursorPos(1, cy + 1)
    end
  end
end

-- print() gets to be global.
function _G.print(...)
  local args = table.pack(...)

  for i=1, args.n, 1 do
    args[i] = tostring(args[i])
  end

  return rc.write(table.concat(args, "  ") .. "\n")
end

function rc.printError(...)
  local old = rc.term.getTextColor()
  rc.term.setTextColor(rc.colors.red)
  print(...)
  rc.term.setTextColor(old)
end

-- get rid of Lua 5.1 things.
if _VERSION == "Lua 5.1" then
  rc.lua51 = {
    load = rm("load"),
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
      result, err = rc.lua51.load(x, name)
    end

    if result then
      env._ENV = env
      rc.lua51.setfenv(result, env)
    end

    return result, err
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

function _G.dofile(file)
  return assert(loadfile(file))()
end

print("Loading startup scripts.")

-- load some wrapper APIs.
local files = rc.fs.list(rc._ROM_DIR.."/init")
table.sort(files)
for _, file in ipairs(files) do
  print(file)
  assert(loadfile(rc._ROM_DIR.."/init/"..file))(rc)
end

print("Starting coroutine manager.")

rc.thread.start()
