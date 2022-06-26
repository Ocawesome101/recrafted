-- package library --

local rc = ...

_G.package = {}

package.config = "/\n;\n?\n!\n-"
package.cpath = ""
package.path = string.gsub("$/apis/?.lua;$/modules/main/?.lua;./lib/?.lua;./lib/?/init.lua;./?.lua;./?/init.lua",
  "%$", rc._ROM_DIR)

package.loaded = {
  _G = _G,
  os = os,
  rc = rc,
  math = math,
  utf8 = utf8,
  table = table,
  debug = debug,
  bit32 = bit32,
  string = string,
  package = package,
  coroutine = coroutine,
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

  -- search 'rc' for the given thing
  function(mod)
    if mod:match("^rc[/%.]") then
      local sub = mod:sub(3)
      if rc[sub] then
        return rc[sub]
      end
    elseif rc[mod] then
      return rc[mod]
    end

    return nil, "no 'rc' definition for '"..mod.."'"
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

local fs = rc.fs

function package.searchpath(name, path, sep, rep)
  rc.expect(1, name, "string")
  rc.expect(2, path, "string")
  rc.expect(3, sep, "string", "nil")
  rc.expect(4, rep, "string", "nil")

  sep = "%" .. (sep or ".")
  rep = rep or "/"

  name = name:gsub(sep, rep)
  local serr = ""

  for search in path:gmatch("[^;]+") do
    search = search:gsub("%?", name)
    if search:sub(1,1) == "." then
      search = fs.combine(require("thread").dir(), search)
    end

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
  rc.expect(1, mod, "string")

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

_G.io = require("io")
package.loaded.colours = require("colors")
