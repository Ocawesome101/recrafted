-- some term things
-- e.g. redirects, read()

local rc = ...

local native = rc.term
local redirect = rc.term

local term = {}
rc.term = term

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
  getPaletteColour = true
}

for k in pairs(valid) do
  term[k] = function(...)
    if not redirect[k] then
      error("redirect object does not implement term."..k, 2)
    end

    return redirect[k](...)
  end
end

function term.current()
  return redirect
end

function term.redirect(obj)
  rc.expect(1, obj, "table")
  local old = redirect
  redirect = obj
  return old
end

local keys = require("keys")

-- read
function term.read(replace, history, complete, default)
  rc.expect(1, replace, "string", "nil")
  rc.expect(2, history, "table", "nil")
  rc.expect(3, complete, "function", "nil")
  rc.expect(4, default, "string", "nil")

  if replace then replace = replace:sub(1, 1) end
  history = history or {}

  local buffer = default or ""
  history[#history+1] = buffer

  local hist_pos = #history
  local cursor_pos = 0

  local stx, sty = term.getCursorPos()
  local w, h = term.getSize()

  local dirty = false
  local completions = {}
  local comp_id = 0

  local function full_redraw(force)
    if force or dirty then
      term.setCursorPos(stx, sty)
      local text = buffer
      if replace then text = replace:rep(#text) end
      local ln = rc.write(text .. " ")

      completions = {}

      if sty + ln > h then
        term.scroll(sty + ln - h)
        sty = sty - (sty + ln - h)
      end
    end

    -- set cursor to the appropriate spot
    local cx, cy = stx, sty
    cx = cx + #buffer - cursor_pos + #(completions[comp_id] or "")
    while cx > w do
      cx = cx - w
      cy = cy + 1
    end
    term.setCursorPos(cx, cy)
  end

  term.setCursorBlink(true)

  -- TODO: text completion support
  while true do
    full_redraw()
    -- get input
    local evt, id = os.pullEvent()

    if evt == "char" then
      dirty = true
      buffer = buffer .. id

    elseif evt == "key" then
      id = keys.getName(id)

      if id == "backspace" and #buffer > 0 then
        dirty = true
        if cursor_pos == 0 then
          buffer = buffer:sub(1, -2)
        elseif cursor_pos < #buffer then
          buffer = buffer:sub(0, -cursor_pos - 2)..buffer:sub(-cursor_pos)
        end

      elseif id == "up" then
        if hist_pos > 1 then
          cursor_pos = 0

          history[hist_pos] = buffer
          hist_pos = hist_pos - 1

          buffer = (" "):rep(buffer)
          full_redraw(true)

          buffer = history[hist_pos]
          dirty = true
        end

      elseif id == "down" then
        if hist_pos < #history then
          cursor_pos = 0

          history[hist_pos] = buffer
          hist_pos = hist_pos + 1

          buffer = (" "):rep(buffer)
          full_redraw(true)

          buffer = history[hist_pos]
          dirty = true
        end

      elseif id == "left" then
        if cursor_pos < #buffer then
          cursor_pos = cursor_pos + 1
        end

      elseif id == "right" then
        if cursor_pos > 0 then
          cursor_pos = cursor_pos - 1
        end

      elseif id == "home" then
        cursor_pos = #buffer

      elseif id == "end" then
        cursor_pos = 0

      elseif id == "enter" then
        rc.write("\n")
        break
      end
    end
  end

  term.setCursorBlink(false)

  return buffer
end

rc.read = term.read
setmetatable(term, {__index = native})
