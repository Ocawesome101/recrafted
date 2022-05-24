-- define rc.expect/cc.expect

local rc = ...

local _expect = {}

local function checkType(index, valueType, value, ...)
  local expected = table.pack(...)
  local isType = false

  for i=1, expected.n, 1 do
    if type(value) == expected[i] then
      isType = true
      break
    end
  end

  if not isType then
    error(string.format("bad %s %s (%s expected, got %s)", valueType,
      index, table.concat(expected, " or "), type(value)), 3)
  end

  return value
end

function _expect.expect(index, value, ...)
  return checkType(("#%d"):format(index), "argument", value, ...)
end

function _expect.field(tbl, index, ...)
  _expect.expect(1, tbl, "table")
  _expect.expect(2, index, "string")
  return checkType(("%q"):format(index), "field", tbl[index], ...)
end

function _expect.range()
end

setmetatable(_expect, {__call = function(_, ...)
  return _expect.expect(...)
end})

rc.expect = _expect.expect
package.loaded["cc.expect"] = _expect
