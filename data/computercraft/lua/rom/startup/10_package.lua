-- package library --

local rc = ...

_G.package = {}

package.config = "/\n;\n?\n!\n-"
package.cpath = ""
package.path = "/rc/apis/?.lua;/rc/modules/main/?.lua;./lib/?.lua;./lib/?/init.lua;./?.lua;./?/init.lua"

local function rm(api)
  local tab = _G[api]
  _G[api] = nil
  return tab
end

package.loaded = {
  _G = _G,
  os = os,
  rc = rc,
  math = math,
  utf8 = utf8,
  table = table,
  debug = debug,
  bit32 = rawget(_G, "bit32"),
  string = string,
  package = package,
  coroutine = coroutine,

  -- CC-specific ones
  peripheral = rm("peripheral"),
  redstone = rm("redstone"),
  commands = rm("commands"),
  pocket = rm("pocket"),
  turtle = rm("turtle"),
  http = rm("http"),
  term = rm("term"),
  fs = rm("fs"),
  rs = rm("rs"),

  -- CraftOS-PC APIs
  periphemu = rm("periphemu"),
  mounter = rm("mounter"),
  config = rm("config"),

  -- CCEmuX API
  ccemux = rm("ccemux")
}

package.preload = {}

package.searchers = {
  -- check package.preload
  function(mod)
    if package.preload[mod] then
      return package.preload[mod]
    else
      return nil, "no field package.preload['" .. mod .. "']"
    end
  end,

  -- check for lua library
  function(mod)
    local ok, err = package.searchpath(mod, package.path, ".", "/")
    if not ok then
      return nil, err
    end

    local func, loaderr = loadfile(ok)
    if not func then
      return nil, loaderr
    end
    return func()
  end,
}

local fs = package.loaded.fs
-- require isn't here yet
local expect = loadfile("/rc/modules/main/cc/expect.lua")()
package.loaded["cc.expect"] = expect

function package.searchpath(name, path, sep, rep)
  expect(1, name, "string")
  expect(2, path, "string")
  expect(3, sep, "string", "nil")
  expect(4, rep, "string", "nil")

  sep = "%" .. (sep or ".")
  rep = rep or "/"

  name = name:gsub(sep, rep)
  local serr = ""

  for search in path:gmatch("[^;]+") do
    search = search:gsub("%?", name)

    if fs.exists(search) then
      return search

    else
      if #serr > 0 then
        serr = serr .. "\n  "
      end

      serr = serr .. "no file '" .. search .. "'"
    end
  end

  return nil, serr
end

function _G.require(mod)
  expect(1, mod, "string")

  if package.loaded[mod] then
    return package.loaded[mod]
  end

  local serr = "module '" .. mod .. "' not found:"
  for _, searcher in ipairs(package.searchers) do
    local result, err = searcher(mod)
    if result then
      package.loaded[mod] = result
      return result
    else
      serr = serr .. "\n  " .. err
    end
  end

  error(serr, 2)
end
