-- rc.peripheral

local old = require("peripheral")
local expect = require("cc.expect").expect

local p = {}
package.loaded.peripheral = p

local sides = {"bottom", "top", "left", "right", "front", "back"}

function p.getNames()
  local names = {}

  for i=1, #sides, 1 do
    local side = sides[i]
    if old.isPresent(side) then
      names[#names+1] = side

      if old.hasType(side, "modem") and not old.call(side, "isWireless") then
        local remote_names = old.call(side, "getNamesRemote")
        for j=1, #remote_names, 1 do
          names[#names+1] = remote_names[j]
        end
      end
    end
  end

  return names
end

-- figure out where a peripheral is
-- returns 0 if the peripheral is directly connected,
-- and a side if it's connected through a modem
local function findByName(name)
  if old.isPresent(name) then
    return 0

  else
    for i=1, #sides, 1 do
      local side = sides[i]

      if old.hasType(side, "modem") and not old.call(side, "isWireless") then
        if old.call(side, "isPresentRemote", name) then
          return side
        end
      end
    end
  end
end

function p.isPresent(name)
  expect(1, name, "string")

  return not not findByName(name)
end

function p.getType(per)
  expect(1, per, "string", "table")

  if type(per) == "string" then
    local place = findByName(per)

    if place == 0 then
      return old.getType(per)

    elseif place then
      return old.call(place, "getTypeRemote", per)
    end

  else
    return table.unpack(per.__types)
  end
end

function p.hasType(per, ptype)
  expect(1, per, "string", "table")
  expect(2, ptype, "string")

  if type(per) == "string" then
    local place = findByName(per)

    if place == 0 then
      return old.hasType(per, ptype)

    elseif place then
      return old.call(place, "hasTypeRemote", per, ptype)
    end

  else
    return per.__types[ptype]
  end
end

function p.getMethods(name)
  expect(1, name, "string")

  local place = findByName(name)
  if place == 0 then
    return old.getMethods(name)

  elseif place then
    return old.call(place, "getMethodsRemote", name)
  end
end

function p.getName(per)
  expect(1, per, "table")
  return per.__info.name
end

function p.call(name, method, ...)
  expect(1, name, "string")
  expect(2, method, "string")

  local place = findByName(name)
  if place == 0 then
    return old.call(name, method, ...)

  elseif place then
    return old.call(place, "callRemote", name, method, ...)
  end
end

function p.wrap(name)
  expect(1, name, "string")

  local place = findByName(name)
  if not place then return end

  local methods, types
  if place == 0 then
    methods = old.getMethods(name)
    types = table.pack(old.getType(name))
  else
    methods = old.call(place, "getMethodsRemote", name)
    types = table.pack(old.call(place, "getTypesRemote", name))
  end

  for i=1, #types, 1 do
    types[types[i]] = true
  end

  local wrapper = {
    __info = {
      name = name,
      types = types,
    }
  }

  if place == 0 then
    for i=1, #methods, 1 do
      wrapper[methods[i]] = function(...)
        return old.call(name, methods[i], ...)
      end
    end

  else
    for i=1, #methods, 1 do
      wrapper[methods[i]] = function(...)
        return old.call(place, "callRemote", name, methods[i], ...)
      end
    end
  end

  return wrapper
end

function p.find(ptype, filter)
  expect(1, ptype, "string")
  expect(2, filter, "function", "nil")

  local wrapped = {}

  for _, name in ipairs(p.getNames()) do
    if p.hasType(name, ptype) then
      local wrapper = p.wrap(name)
      if (p.filter and p.filter(name, wrapper)) or not p.filter then
        wrapped[#wrapped+1] = wrapper
      end
    end
  end

  return table.unpack(wrapped)
end
