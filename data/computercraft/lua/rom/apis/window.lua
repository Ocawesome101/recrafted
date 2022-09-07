-- window api

local term = require("term")
local colors = require("colors")
local expect = require("cc.expect").expect
local range = require("cc.expect").range
local window = {}

local rep = string.rep
local sub = string.sub
local max = math.max
local min = math.min

local function into_buffer(buf, x, y, text)
  if not text then return end
  if not buf[y] then return end
  text = sub(text, 1, #buf[y] - x + 1)
  if x < 1 then
    text = sub(text, -x + 2)
    x = 1
  end
  local olen = #buf[y]
  if x + #text > olen then
    buf[y] = sub(buf[y], 0, max(0, x-1)) .. text
  else
    buf[y] = sub(buf[y], 0, max(0, x-1)) .. text .. buf[y]:sub(x + #text)
  end
  buf[y] = sub(buf[y], 1, olen)
end

function window.create(parent, x, y, width, height, visible)
  if type(parent) ~= "table" then expect(1, parent, "table") end
  if parent == term then
    error("do not pass 'term' as a window parent", 0)
  end
  if type(x) ~= "number" then expect(2, x, "number") end
  if type(y) ~= "number" then expect(3, y, "number") end
  if type(width) ~= "number" then expect(4, width, "number") end
  if type(height) ~= "number" then expect(5, height, "number") end
  if type(visible) ~= "boolean" then expect(6, visible, "boolean", "nil") end
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

  local function drawLine(i)
    parent.setCursorPos(x, y + i - 1)
    parent.blit(textbuf[i], fgbuf[i], bgbuf[i])
  end

  local function draw()
    local blink = parent.getCursorBlink()
    parent.setCursorBlink(false)
    for i=1, height, 1 do
      drawLine(i)
    end
    parent.setCursorBlink(blink)
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
    if type(text) ~= "string" then expect(1, text, "string") end
    local fg, bg = rep(foreground, #text), background:rep(#text)
    into_buffer(textbuf, cursorX, cursorY, text)
    into_buffer(fgbuf, cursorX, cursorY, fg)
    into_buffer(bgbuf, cursorX, cursorY, bg)
    cursorX = max(-100, min(cursorX + #text, width + 1))
    if visible then win.redraw() end
  end

  function win.blit(text, tcol, bcol)
    if type(text) ~= "string" then expect(1, text, "string") end
    if type(tcol) ~= "string" then expect(2, tcol, "string") end
    if type(bcol) ~= "string" then expect(3, bcol, "string") end
    assert(#text == #tcol and #text == #bcol, "mismatched argument lengths")

    into_buffer(textbuf, cursorX, cursorY, text)
    into_buffer(fgbuf, cursorX, cursorY, tcol)
    into_buffer(bgbuf, cursorX, cursorY, bcol)
    cursorX = max(0, min(cursorX + #text, width + 1))

    if visible then
      drawLine(cursorY)
      restoreCursorColor()
      restoreCursorPos()
    end
  end

  function win.clear()
    local fore = rep(foreground, width)
    local back = rep(background, width)
    local blank = rep(" ", width)

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
    local emptyText, emptyFg, emptyBg =
      rep(" ", width),
      rep(foreground, width),
      rep(background, width)

    textbuf[cursorY] = emptyText
    fgbuf[cursorY] = emptyFg
    bgbuf[cursorY] = emptyBg

    if visible then
      win.redraw()
    end
  end

  function win.getCursorPos()
    return cursorX, cursorY
  end

  function win.setCursorPos(_x, _y)
    if type(_x) ~= "number" then expect(1, _x, "number") end
    if type(_y) ~= "number" then expect(2, _y, "number") end

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
    if type(color) ~= "number" then expect(1, color, "number") end
    foreground = colors.toBlit(color) or foreground
    if visible then
      restoreCursorColor()
    end
  end

  win.setTextColour = win.setTextColor

  function win.setPaletteColor(color, r, g, b)
    if type(color) ~= "number" then expect(1, color, "number") end
    if type(r) ~= "number" then expect(2, r, "number") end

    if r < 1 then
      if type(g) ~= "number" then expect(3, g, "number") end
      if type(b) ~= "number" then expect(4, b, "number") end
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
    if type(color) ~= "number" then expect(1, color, "number") end
    return palette[math.floor(math.log(color, 2))]
  end

  win.getPaletteColour = win.getPaletteColor

  function win.setBackgroundColor(color)
    if type(color) ~= "number" then expect(1, color, "number") end
    background = colors.toBlit(color)
  end

  win.setBackgroundColour = win.setBackgroundColor

  function win.getSize()
    return width, height
  end

  function win.scroll(n)
    if type(n) ~= "number" then expect(1, n, "number") end

    if n == 0 then return end
    local fg = rep(foreground, width)
    local bg = rep(background, width)
    local blank = rep(" ", width)

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
    if type(ly) ~= "number" then expect(1, ly, "number") end
    if ly < 1 or ly > height then range(ly, 1, height) end
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

  local function resize_buffer(buf, nw, nh, c)
    if nw > width then
      for i=1, #buf, 1 do
        buf[i] = buf[i] .. sub(rep(buf[i], -1), nw - width)
      end
    end

    if nh > #buf then
      for _=1, nh - #buf, 1 do
        buf[#buf+1] = rep(c, nw)
      end
    end
  end

  function win.reposition(nx, ny, nw, nh, npar)
    if type(nx) ~= "number" then expect(1, nx, "number") end
    if type(ny) ~= "number" then expect(2, ny, "number") end
    if type(nw) ~= "number" then expect(3, nw, "number", "nil") end
    if type(nh) ~= "number" then expect(4, nh, "number", "nil") end
    if type(npar) ~= "table" then expect(5, npar, "table", "nil") end

    x, y, width, height, parent =
      nx or x, ny or y,
      nw or width, nh or height,
      npar or parent

    resize_buffer(textbuf, width, height, " ")
    resize_buffer(fgbuf, width, height, "0")
    resize_buffer(bgbuf, width, height, "f")

    if visible then
      win.redraw()
    end
  end

  function win.at(_x, _y)
    win.setCursorPos(_x, _y)
    return win
  end

  win.clear()
  return win
end

return window
