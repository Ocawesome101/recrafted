-- some term things
-- e.g. redirects, read()

local rc = ...

-- we need a couple of these
local colors = require("colors")
local native = require("term")
local strings = require("cc.strings")
local expect = require("cc.expect").expect

local term = {}
package.loaded.term = term
local thread = require("rc.thread")

local valid = {
  write = true,
  scroll = true,
  getCursorPos = true,
  setCursorPos = true,
  getCursorBlink = true,
  setCursorBlink = true,
  getSize = true,
  clear = true,
  clearLine = true,
  getTextColor = true,
  getTextColour = true,
  setTextColor = true,
  setTextColour = true,
  getBackgroundColor = true,
  getBackgroundColour = true,
  setBackgroundColor = true,
  setBackgroundColour = true,
  isColor = true,
  isColour = true,
  blit = true,
  setPaletteColor = true,
  setPaletteColour = true,
  getPaletteColor = true,
  getPaletteColour = true,

  -- CraftOS-PC graphics mode settings
  setGraphicsMode = not not native.setGraphicsMode,
  getGraphicsMode = not not native.getGraphicsMode,
  drawPixels = not not native.drawPixels,
  getPixels = not not native.getPixels,
  setPixel = not not native.setPixel,
  getPixel = not not native.getPixel
}

for k in pairs(valid) do
  term[k] = function(...)
    local redirect = thread.getTerm()
    if not redirect[k] then
      error("redirect object does not implement term."..k, 2)
    end

    return redirect[k](...)
  end
end

function term.current()
  return thread.getTerm()
end

function term.native()
  return native
end

function term.redirect(obj)
  expect(1, obj, "table")
  return thread.setTerm(obj)
end

function term.at(x, y)
  term.setCursorPos(x, y)
  return term
end

local keys = require("keys")

-- rc.write
-- [[
function rc.write(text)
  expect(1, text, "string")

  local lines = 0
  local w, h = term.getSize()
  local x, y = term.getCursorPos()

  local elements = strings.splitElements(text, w)

  strings.wrappedWriteElements(elements, w, false, {
    newline = function()
      lines = lines + 1

      x = 1
      if y >= h then
        term.scroll(1)
      else
        y = y + 1
      end

      term.at(x, y)
    end,

    append = function(newText)
      term.at(x, y).write(newText)
      x = x + #newText
    end,

    getX = function()
      return x
    end
  })

  return lines
end

--]]

-- old write() used for redrawing in read()
local function write(text)
  expect(1, text, "string")

  local lines = 0
  local w, h = term.getSize()

  local function inc_cy(cy)
    lines = lines + 1

    if cy > h - 1 then
      term.scroll(1)
      return cy
    else
      return cy + 1
    end
  end

  while #text > 0 do
    local nl = text:find("\n") or #text
    local chunk = text:sub(1, nl)
    text = text:sub(#chunk + 1)

    local has_nl = chunk:sub(-1) == "\n"
    if has_nl then chunk = chunk:sub(1, -2) end

    local cx, cy = term.getCursorPos()
    while #chunk > 0 do
      if cx > w then
        term.setCursorPos(1, inc_cy(cy))
        cx, cy = term.getCursorPos()
      end

      local to_write = chunk:sub(1, w - cx + 1)
      term.write(to_write)

      chunk = chunk:sub(#to_write + 1)
      cx, cy = term.getCursorPos()
    end

    if has_nl then
      term.setCursorPos(1, inc_cy(cy))
    end
  end

  return lines
end--]]

-- read
local empty = {}
function term.read(replace, history, complete, default)
  expect(1, replace, "string", "nil")
  expect(2, history, "table", "nil")
  expect(3, complete, "function", "nil")
  expect(4, default, "string", "nil")

  if replace then replace = replace:sub(1, 1) end
  local hist = history or {}
  history = {}
  for i=1, #hist, 1 do
    history[i] = hist[i]
  end

  local buffer = default or ""
  local prev_buf = buffer
  history[#history+1] = buffer

  local hist_pos = #history
  local cursor_pos = 0

  local stx, sty = term.getCursorPos()
  local w, h = term.getSize()

  local dirty = false
  local completions = {}
  local comp_id = 0

  local function clearCompletion()
    if completions[comp_id] then
      write((" "):rep(#completions[comp_id]))
    end
  end

  local function full_redraw(force)
    if force or dirty then
      if complete and buffer ~= prev_buf then
        completions = complete(buffer) or empty
        comp_id = math.min(1, #completions)
      end
      prev_buf = buffer

      term.setCursorPos(stx, sty)
      local text = buffer
      if replace then text = replace:rep(#text) end
      local ln = write(text)

      if completions[comp_id] then
        local oldfg = term.getTextColor()
        local oldbg = term.getBackgroundColor()
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.gray)
        ln = ln + write(completions[comp_id])
        term.setTextColor(oldfg)
        term.setBackgroundColor(oldbg)
      else
        ln = ln + write(" ")
      end

      if sty + ln > h then
        sty = sty - (sty + ln - h)
      end
    end

    -- set cursor to the appropriate spot
    local cx, cy = stx, sty
    cx = cx + #buffer - cursor_pos-- + #(completions[comp_id] or "")
    while cx > w do
      cx = cx - w
      cy = cy + 1
    end
    term.setCursorPos(cx, cy)
  end

  term.setCursorBlink(true)

  while true do
    full_redraw()
    -- get input
    local evt, id = rc.pullEvent()

    if evt == "char" then
      dirty = true
      clearCompletion()
      if cursor_pos == 0 then
        buffer = buffer .. id
      elseif cursor_pos == #buffer then
        buffer = id .. buffer
      else
        buffer = buffer:sub(0, -cursor_pos - 1)..id..buffer:sub(-cursor_pos)
      end

    elseif evt == "paste" then
      dirty = true
      clearCompletion()
      if cursor_pos == 0 then
        buffer = buffer .. id
      elseif cursor_pos == #buffer then
        buffer = id .. buffer
      else
        buffer = buffer:sub(0, -cursor_pos - 1)..id..
          buffer:sub(-cursor_pos+(#id-1))
      end

    elseif evt == "key" then
      id = keys.getName(id)

      if id == "backspace" and #buffer > 0 then
        dirty = true
        if cursor_pos == 0 then
          buffer = buffer:sub(1, -2)
          clearCompletion()
        elseif cursor_pos < #buffer then
          buffer = buffer:sub(0, -cursor_pos - 2)..buffer:sub(-cursor_pos)
        end

      elseif id == "delete" and cursor_pos > 0 then
        dirty = true

        if cursor_pos == #buffer then
          buffer = buffer:sub(2)
        elseif cursor_pos == 1 then
          buffer = buffer:sub(1, -2)
        else
          buffer = buffer:sub(0, -cursor_pos - 1) .. buffer:sub(-cursor_pos + 1)
        end
        cursor_pos = cursor_pos - 1

      elseif id == "up" then
        if #completions > 1 then
          dirty = true
          clearCompletion()
          if comp_id > 1 then
            comp_id = comp_id - 1
          else
            comp_id = #completions
          end

        elseif hist_pos > 1 then
          cursor_pos = 0

          history[hist_pos] = buffer
          hist_pos = hist_pos - 1

          buffer = (" "):rep(#buffer)
          full_redraw(true)

          buffer = history[hist_pos]
          dirty = true
        end

      elseif id == "down" then
        if #completions > 1 then
          dirty = true
          clearCompletion()
          if comp_id < #completions then
            comp_id = comp_id + 1
          else
            comp_id = 1
          end

        elseif hist_pos < #history then
          cursor_pos = 0

          history[hist_pos] = buffer
          hist_pos = hist_pos + 1

          buffer = (" "):rep(#buffer)
          full_redraw(true)

          buffer = history[hist_pos]
          dirty = true
        end

      elseif id == "left" then
        if cursor_pos < #buffer then
          clearCompletion()
          cursor_pos = cursor_pos + 1
        end

      elseif id == "right" then
        if cursor_pos > 0 then
          cursor_pos = cursor_pos - 1

        elseif comp_id > 0 then
          dirty = true
          buffer = buffer .. completions[comp_id]
        end

      elseif id == "tab" then
        if comp_id > 0 then
          dirty = true
          buffer = buffer .. completions[comp_id]
        end

      elseif id == "home" then
        cursor_pos = #buffer

      elseif id == "end" then
        cursor_pos = 0

      elseif id == "enter" then
        clearCompletion()
        write("\n")
        break
      end
    end
  end

  term.setCursorBlink(false)

  return buffer
end

rc.read = term.read
setmetatable(term, {__index = native})
