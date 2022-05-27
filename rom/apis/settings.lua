-- rc.settings

local rc = require("rc")
local expect = require("cc.expect")

local settings = {}
local defs = {}
local set = {}

function settings.define(name, opts)
  rc.expect(1, name, "string")
  rc.expect(2, opts, "table", "nil")

  opts = opts or {}
  opts.description = expect.field(opts, "description", "string", "nil")
  opts.type = expect.field(opts, "type", "string", "nil")
  defs[name] = opts
end

function settings.undefine(name)
  rc.expect(1, name, "string")
  defs[name] = nil
end

function settings.set(name, value)
  rc.expect(1, name, "string")

  if defs[name] and defs[name].type then
    rc.expect(2, value, defs[name].type)
  else
    rc.expect(2, value, "number", "string", "boolean")
  end

  set[name] = value
end

function settings.get(name, default)
  rc.expect(1, name, "string")
  return set[name] or default or defs[name].default
end

function settings.getDetails(name)
  rc.expect(1, name, "string")
  local def = defs[name]
  return {
    description = def.description,
    default = def.default,
    value = set[name],
    type = def.type,
  }
end

function settings.unset(name)
  rc.expect(1, name, "string")
  set[name] = nil
end

function settings.clear()
  set = {}
end

function settings.getNames()
  local names = {}
  for k in pairs(defs) do
    names[#names+1] = k
  end
  table.sort(names)
  return names
end

function settings.load(path)
  rc.expect(1, path, "string", "nil")

  path = path or ".settings"
  local handle = rc.fs.open(path, "r")
  if not handle then
    return false
  end

  local data = handle.readAll()
  handle.close()

  local new = rc.textutils.unserialize(data)
  if not new then return false end
  for k, v in pairs(new) do
    set[k] = v
  end

  return true
end

function settings.save(path)
  rc.expect(1, path, "string", "nil")

  path = path or ".settings"
  local data = rc.textutils.serialize(set)

  local handle = rc.fs.open(path, "w")
  if not handle then return false end

  handle.write(data)
  handle.close()

  return true
end

return settings
