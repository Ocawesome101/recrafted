-- window api

local term = require("term")
local colors = require("colors")
local expect = require("cc.expect").expect
local range = require("cc.expect").range
local window = {}

local function into_buffer(buf, x, y, text)
  if not text then return end
  if not buf[y] then return end
  text = text:sub(1, #buf[y] - x + 1)
  if x < 1 then
    text = text:sub(-x + 1)
    x = 1
  end
  local olen = #buf[y]
  if x + #text > olen then
    buf[y] = buf[y]:sub(0, math.max(0, x-1)) .. text
  else
    buf[y] = buf[y]:sub(0, math.max(0, x-1)) .. text .. buf[y]:sub(x + #text)
  end
  buf[y] = buf[y]:sub(1, olen)
end

function window.create(parent, x, y, width, height, visible)
  expect(1, parent, "table")
  if parent == term then
    error("do not pass 'term' as a window parent", 0)
  end
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, width, "number")
  expect(5, height, "number")
  expect(6, visible, "boolean", "nil")
  if visible == nil then visible = true end

  local cursorX, cursorY, cursorBlink = 1, 1, false
  local foreground, background = colors.toBlit(colors.white),
    colors.toBlit(colors.black)
  local textbuf, fgbuf, bgbuf = {}, {}, {}

  local win = {}

  local palette = {}
  for i=0, 15, 1 do
    palette[i] = colors.packRGB(parent.getPaletteColor(2^i))
  end

  local function draw()
    for i=1, height, 1 do
      parent.setCursorPos(x, y + i - 1)
      parent.blit(textbuf[i], fgbuf[i], bgbuf[i])
    end
  end

  local function restorePalette()
    for i=0, 15, 1 do
      parent.setPaletteColor(2^i, palette[i])
    end
  end

  local function restoreCursorBlink()
    parent.setCursorBlink(cursorBlink)
  end

  local function restoreCursorPos()
    if cursorX > 0 and cursorY > 0 and
       cursorX <= width and cursorY <= height then
      parent.setCursorPos(x + cursorX - 1, y + cursorY - 1)
    else
      parent.setCursorPos(0, 0)
    end
  end

  local function restoreCursorColor()
    parent.setTextColor(2^tonumber(foreground, 16))
  end

  function win.write(text)
    expect(1, text, "string")
    local fg, bg = foreground:rep(#text), background:rep(#text)
    into_buffer(textbuf, cursorX, cursorY, text)
    into_buffer(fgbuf, cursorX, cursorY, fg)
    into_buffer(bgbuf, cursorX, cursorY, bg)
    cursorX = math.max(0, math.min(cursorX + #text, width + 1))
    if visible then win.redraw() end
  end

  function win.blit(text, tcol, bcol)
    expect(1, text, "string")
    expect(2, tcol, "string")
    expect(3, bcol, "string")
    assert(#text == #tcol and #text == #bcol, "mismatched argument lengths")

    into_buffer(textbuf, cursorX, cursorY, text)
    into_buffer(fgbuf, cursorX, cursorY, tcol)
    into_buffer(bgbuf, cursorX, cursorY, bcol)
    cursorX = math.max(0, math.min(cursorX + #text, width + 1))
    if visible then win.redraw() end
  end

  function win.clear()
    local fore = string.rep(foreground, width)
    local back = string.rep(background, width)
    local blank = string.rep(" ", width)

    for i=1, height, 1 do
      textbuf[i] = blank
      fgbuf[i] = fore
      bgbuf[i] = back
    end

    if visible then
      win.redraw()
    end
  end

  function win.clearLine()
    textbuf[cursorY] = string.rep(" ", width)
    fgbuf[cursorY] = string.rep(foreground, width)
    bgbuf[cursorY] = string.rep(background, width)

    if visible then
      win.redraw()
    end
  end

  function win.getCursorPos()
    return cursorX, cursorY
  end

  function win.setCursorPos(_x, _y)
    expect(1, _x, "number")
    expect(2, _y, "number")

    cursorX, cursorY = _x, _y
    if visible then
      restoreCursorPos()
    end
  end

  function win.setCursorBlink(blink)
    cursorBlink = not not blink
    if visible then
      restoreCursorBlink()
    end
  end

  function win.getCursorBlink()
    return cursorBlink
  end

  function win.isColor()
    return parent.isColor()
  end

  win.isColour = win.isColor

  function win.setTextColor(color)
    expect(1, color, "number")
    foreground = colors.toBlit(color) or foreground
    if visible then
      restoreCursorColor()
    end
  end

  win.setTextColour = win.setTextColor

  function win.setPaletteColor(color, r, g, b)
    expect(1, color, "number")
    expect(2, r, "number")

    if r < 1 then
      expect(3, g, "number")
      expect(4, b, "number")
      palette[math.floor(math.log(color, 2))] = colors.packRGB(r, g, b)
    else
      palette[math.floor(math.log(color, 2))] = r
    end

    if visible then
      restorePalette()
    end
  end

  win.setPaletteColour = win.setPaletteColor

  function win.getPaletteColor(color)
    expect(1, color, "number")
    return palette[math.floor(math.log(color, 2))]
  end

  win.getPaletteColour = win.getPaletteColor

  function win.setBackgroundColor(color)
    expect(1, color, "number")
    background = colors.toBlit(color)
  end

  win.setBackgroundColour = win.setBackgroundColor

  function win.getSize()
    return width, height
  end

  function win.scroll(n)
    expect(1, n, "number")

    if n == 0 then return end
    local fg = string.rep(foreground, width)
    local bg = string.rep(background, width)
    local blank = string.rep(" ", width)

    if n > 0 then
      for _=1, n, 1 do
        table.remove(textbuf, 1)
        textbuf[#textbuf+1] = blank
        table.remove(fgbuf, 1)
        fgbuf[#fgbuf+1] = fg
        table.remove(bgbuf, 1)
        bgbuf[#bgbuf+1] = bg
      end
    else
      for _=1, -n, 1 do
        table.insert(textbuf, 1, blank)
        textbuf[#textbuf] = nil
        table.insert(fgbuf, 1, fg)
        fgbuf[#fgbuf] = nil
        table.insert(bgbuf, 1, bg)
        bgbuf[#bgbuf] = nil
      end
    end

    if visible then
      win.redraw()
    end
  end

  function win.getTextColor()
    return 2^tonumber(foreground, 16)
  end

  win.getTextColour = win.getTextColor

  function win.getBackgroundColor()
    return 2^tonumber(background, 16)
  end

  win.getBackgroundColour = win.getBackgroundColor

  function win.getLine(ly)
    range(expect(1, ly, "number"), 1, height)
    return textbuf[ly], fgbuf[ly], bgbuf[ly]
  end

  function win.setVisible(vis)
    if vis and not visible then
      draw()
      restorePalette()
      restoreCursorBlink()
      restoreCursorPos()
      restoreCursorColor()
    end
    visible = not not vis
  end

  function win.redraw()
    if visible then
      draw()
      restorePalette()
      restoreCursorPos()
      restoreCursorBlink()
      restoreCursorColor()
    end
  end

  function win.restoreCursor()
    if visible then
      restoreCursorBlink()
      restoreCursorPos()
      restoreCursorColor()
    end
  end

  function win.getPosition()
    return x, y
  end

  local function resize_buffer(buf, nw, nh)
    if nh > #buf then
      for _=1, nh - #buf, 1 do
        buf[#buf+1] = buf[#buf]
      end
    end

    if nw > width then
      for i=1, #buf, 1 do
        buf[i] = buf[i] .. buf[i]:sub(-1):rep(nw - width)
      end
    end
  end

  function win.reposition(nx, ny, nw, nh, npar)
    expect(1, nx, "number")
    expect(2, ny, "number")
    expect(3, nw, "number", "nil")
    expect(4, nh, "number", "nil")
    expect(5, npar, "table", "nil")

    x, y, width, height, parent =
      nx or x, ny or y,
      nw or width, nh or height,
      npar or parent

    resize_buffer(textbuf, width, height)
    resize_buffer(fgbuf, width, height)
    resize_buffer(bgbuf, width, height)

    if visible then
      win.redraw()
    end
  end

  win.clear()
  return win
end

return window
