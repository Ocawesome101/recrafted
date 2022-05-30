-- editor

local args = {...}

local keys = require("keys")
local term = require("term")
local shell = require("shell")
local colors = require("colors")
local settings = require("settings")

local scroll_offset = settings.get("edit.scroll_offset")

local state = {
  file = args[1] or ".new",
  unsaved = false,
  scroll = 0,
  hscroll = 0,
  lines = {""},
  status = "Press Control for menu",
  cx = 1,
  cy = 1,
}

if args[1] then
  local path = shell.resolve(args[1])
  local handle, err = io.open(path)
  if not handle then
    error(args[1] .. ": " .. err, 0)
  end

  for line in handle:lines() do
    state.lines[#state.lines+1] = line
  end

  handle:close()

  if not state.lines[1] then state.lines[1] = "" end
end

local function redraw()
  local _, h = term.getSize()

  for i=1, h - 1, 1 do
    local to_write = state.lines[state.scroll + i] or ""
    term.setCursorPos(1, i)
    term.clearLine()
    term.write(to_write)
  end

  term.setCursorPos(1, h)

  term.clearLine()
  term.setTextColor(colors.yellow)
  term.write(state.status)
  term.setTextColor(colors.white)

  term.setCursorPos(state.cx, state.cy - state.scroll)
end

local function processMenuInput()
end

local function processInput()
  local event, id = os.pullEvent()

  local _, h = term.getSize()

  if event == "char" then
    local line = state.lines[state.cy]
    if state.cx == #line then
      line = line .. id

    elseif state.cx == 1 then
      line = id .. line

    else
      line = line:sub(0, state.cx-1)..id..line:sub(state.cx)
    end
    state.cx = state.cx + 1

    state.lines[state.cy] = line

  elseif event == "key" then
    id = keys.getName(id)

    if id == "backspace" then
      local line = state.lines[state.cy]
      if #line > 0 then
        if state.cx == #line then
          line = line:sub(1, -2)

        elseif state.cx > 1 then
          line = line:sub(0, state.cx - 2) .. line:sub(state.cx)
        end
        state.cx = state.cx - 1

        state.lines[state.cy] = line
      end

    elseif id == "up" then
      if state.cy > 1 then
        state.cy = state.cy - 1
        if state.cy - state.scroll < scroll_offset then
          state.scroll = math.max(0, state.cy - scroll_offset)
        end
      end

      state.cx = math.min(state.cx, #state.lines[state.cy] + 1)

    elseif id == "down" then
      if state.cy < #state.lines then
        state.cy = state.cy + 1

        if state.cy - state.scroll > h - scroll_offset then
          state.scroll = math.max(0, math.min(#state.lines - h,
            state.cy - h + scroll_offset))
        end
      end

      state.cx = math.min(state.cx, #state.lines[state.cy] + 1)

    elseif id == "left" then
      if state.cx > 1 then
        state.cx = state.cx - 1
      end

    elseif id == "right" then
      if state.cx < #state.lines[state.cy] + 1 then
        state.cx = state.cx + 1
      end

    end
  end
end

term.clear()
while true do
  term.setCursorBlink(false)
  redraw()
  term.setCursorBlink(true)
  processInput()
end
