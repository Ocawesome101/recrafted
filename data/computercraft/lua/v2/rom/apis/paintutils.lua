-- rc.paintutils

local term = require("term")
local expect = require("cc.expect").expect
local textutils = require("textutils")

local p = {}

function p.parseImage(str)
  expect(1, str, "string")
  return textutils.unserialize(str)
end

function p.loadImage(path)
  expect(1, path, "string")
  local handle = io.open(path)
  if handle then
    local data = handle:read("a")
    handle:close()
    return p.parseImage(data)
  end
end

function p.drawPixel(x, y, color)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(2, color, "number", "nil")
  if color then term.setBackgroundColor(color) end
  term.at(x, y).write(" ")
end

local function drawSteep(x0, y0, x1, y1, color)
  local distX = x1 - x0
  local distY = y1 - y0

  local diff = 2*distX - distY

  local x = x0
  for y=y0, y1, 1 do
    p.drawPixel(x, y, color)
    if diff > 0 then
      x = x + 1
      diff = diff + 2 * (distX - distY)
    else
      diff = diff + 2*distX
    end
  end
end

local function drawShallow(x0, y0, x1, y1, color)
  local distX, distY = x1 - x0, y1 - y0
  local diff = 2*distY - distX
  local y = y0

  for x=x0, x1, 1 do
    p.drawPixel(x, y, color)
    if diff > 0 then
      y = y + 1
      diff = diff - 2*distX
    end
    diff = diff + 2*distY
  end
end


function p.drawLine(_startX, _startY, _endX, _endY, color)
  expect(1, _startX, "number")
  expect(2, _startY, "number")
  expect(3, _endX, "number")
  expect(4, _endY, "number")
  expect(5, color, "number")
  local startX, startY, endX, endY =
    math.min(_startX, _endX), math.min(_startY, _endY),
    math.max(_startX, _endX), math.max(_startY, _endY)

  if startX == endX and startY == endY then
    return p.drawPixel(startX, startY, color)
  elseif startX == endX then
    if color then term.setBackgroundColor(color) end
    for y=startY, endY, 1 do
      term.at(startX, y).write(" ")
    end
  elseif startY == endY then
    if color then term.setBackgroundColor(color) end
    term.at(startX, startY).write((" "):rep(endX - startX))
  end

  if (endY - startY) < (endX - startX) then
    drawShallow(startX, startY, endX, endY)
  else
    drawSteep(startX, startY, endX, endY)
  end
end

function p.drawBox(startX, startY, endX, endY, color)
  expect(1, startX, "number")
  expect(2, startY, "number")
  expect(3, endX, "number")
  expect(4, endY, "number")
  expect(5, color, "number")

  -- -
  p.drawLine(startX, startY, endX, startY, color)
  -- _
  p.drawLine(startX, endY, endX, endY, color)
  -- |
  p.drawLine(startX, startY, startX, endY, color)
  --    |
  p.drawLine(endX, startY, endX, endY, color)
end

function p.drawFilledBox(startX, startY, endX, endY, color)
  expect(1, startX, "number")
  expect(2, startY, "number")
  expect(3, endX, "number")
  expect(4, endY, "number")
  expect(5, color, "number")

  if color then term.setBackgroundColor(color) end
  local line = string.rep(" ", endX - startX + 1)
  for y=startY, endY, 1 do
    term.at(startX, y).write(line)
  end
end

function p.drawImage(img, x, y, frame)
  expect(1, img, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, frame, "number", "nil")

  frame = frame or 1
  if not img[frame] then
    return nil, "invalid frame index " .. frame
  end

  if img.palette then
    for k, v in pairs(img.palette) do
      term.setPaletteColor(k, table.unpack(v))
    end
  end

  if img[frame].palette then
    for k, v in pairs(img[frame].palette) do
      term.setPaletteColor(k, table.unpack(v))
    end
  end

  for i, line in ipairs(img[frame]) do
    term.at(x+i-1, y).blit(table.unpack(line))
  end

  return true
end

return p
