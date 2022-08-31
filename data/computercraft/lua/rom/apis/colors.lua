-- rc.colors

local term = require("term")
local bit32 = require("bit32")
local expect = require("cc.expect")

local colors = {
  white     = 0x1,
  orange    = 0x2,
  magenta   = 0x4,
  lightBlue = 0x8,
  yellow    = 0x10,
  lime      = 0x20,
  pink      = 0x40,
  gray      = 0x80,
  grey      = 0x80,
  lightGray = 0x100,
  lightGrey = 0x100,
  cyan      = 0x200,
  purple    = 0x400,
  blue      = 0x800,
  brown     = 0x1000,
  green     = 0x2000,
  red       = 0x4000,
  black     = 0x8000,
}

local defaults = {
  0xf0f0f0, 0xf2b233, 0xe57fd8, 0x99b2f2,
  0xdede6c, 0x7fcc19, 0xf2b2cc, 0x4c4c4c,
  0x999999, 0x4c99b2, 0xb266e5, 0x3366cc,
  0x7f664c, 0x57a64e, 0xcc4c4c, 0x111111
}

for i=1, #defaults, 1 do
  term.setPaletteColor(2^(i-1), defaults[i])
end

function colors.combine(...)
  local ret = 0
  local cols = {...}
  for i=1, #cols, 1 do
    expect.expect(i, cols[i], "number")
    ret = bit32.bor(ret, cols[i])
  end
  return ret
end

function colors.subtract(cols, ...)
  expect.expect(1, cols, "number")
  local subt = {...}
  for i=1, #subt, 1 do
    expect.expect(i+1, subt[i], "number")
    cols = bit32.band(cols, bit32.bnot(subt[i]))
  end
  return cols
end

colors.test = bit32.btest

function colors.packRGB(r, g, b)
  expect.expect(1, r, "number")
  if r > 1 then return r end
  expect.range(r, 0, 1)
  expect.range(expect.expect(2, g, "number"), 0, 1)
  expect.range(expect.expect(3, b, "number"), 0, 1)
  return (r * 255 * 0x10000) + (g * 255 * 0x100) + (b * 255)
end

function colors.unpackRGB(rgb)
  expect.range(expect.expect(1, rgb, "number"), 0, 0xFFFFFF)
  return bit32.rshift(rgb, 16) / 255,
    bit32.rshift(bit32.band(rgb, 0xFF00), 8) / 255,
    bit32.band(rgb, 0xFF) / 255
end

function colors.toBlit(color)
  expect.expect(1, color, "number")
  return string.format("%x", math.floor(math.log(color, 2)))
end

return colors
