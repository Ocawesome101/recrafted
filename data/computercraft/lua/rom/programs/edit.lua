-- editor

local args = {...}

local rc = require("rc")
local keys = require("keys")
local term = require("term")
local shell = require("shell")
local colors = require("colors")
local settings = require("settings")
local textutils = require("textutils")

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
  local handle = io.open(path)
  state.file = path

  if handle then
    state.lines = {}

    for line in handle:lines() do
      state.lines[#state.lines+1] = line
    end

    handle:close()

    if not state.lines[1] then state.lines[1] = "" end
  end
end

local function redraw()
  local w, h = term.getSize()

  for i=1, h - 1, 1 do
    local to_write = state.lines[state.scroll + i] or ""
    if state.cx > w then
      to_write = to_write:sub(state.cx - (w-1))
    end
    term.at(1, i).clearLine()
    term.write(to_write)
  end

  term.at(1, h).clearLine()
  textutils.coloredWrite(colors.yellow, state.status, colors.white)

  term.setCursorPos(math.min(w, state.cx), state.cy - state.scroll)
end

local run, menu = true, false

local function save()
  if state.file == ".new" then
    local _, h = term.getSize()
    term.setCursorPos(1, h)
    textutils.coloredWrite(colors.yellow, "filename: ", colors.white)
    state.file = term.read()
  end

  local handle, err = io.open(state.file, "w")
  if not handle then
    state.status = err
  else
    for i=1, #state.lines, 1 do
      handle:write(state.lines[i] .. "\n")
    end
    handle:close()
    state.status = "Saved to " .. state.file
    state.unsaved = false
  end
end

local function processMenuInput()
  local event, id = rc.pullEvent()

  if event == "char" then
    if id:lower() == "e" then
      if state.unsaved and menu ~= 2 then
        state.status = "Lose unsaved work? E:yes C:no"
        menu = 2
      else
        term.at(1, 1).clear()
        run = false
      end

    elseif id:lower() == "c" and menu == 2 then
      menu = false

    elseif id:lower() == "s" then
      save()
      menu = false
    end

  elseif event == "key" then
    id = keys.getName(id)

    if id == "leftCtrl" or id == "rightCtrl" then
      state.status = "Press Control for menu"
      menu = false
    end
  end
end

local function processInput()
  local event, id = rc.pullEvent()

  local _, h = term.getSize()

  if event == "char" then
    local line = state.lines[state.cy]
    state.unsaved = true
    if state.cx > #line then
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
      state.unsaved = true
      if state.cx == 1 and state.cy > 1 then
        local previous = table.remove(state.lines, state.cy - 1)
        state.cy = state.cy - 1
        state.cx = #previous + 1
        line = previous .. line
      else
        if #line > 0 then
          if state.cx > #line then
            state.cx = state.cx - 1
            line = line:sub(1, -2)

          elseif state.cx > 1 then
            line = line:sub(0, state.cx - 2) .. line:sub(state.cx)
            state.cx = state.cx - 1

          end

        end
      end
      state.lines[state.cy] = line

    elseif id == "enter" then
      if state.cx == 1 then
        table.insert(state.lines, state.cy, "")
      elseif state.cx > #state.lines[state.cy] then
        table.insert(state.lines, state.cy + 1, "")
      else
        local line = state.lines[state.cy]
        local before, after = line:sub(0, state.cx - 1), line:sub(state.cx)
        state.lines[state.cy] = before
        table.insert(state.lines, state.cy + 1, after)
      end

      state.cy = state.cy + 1
      state.cx = 1

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
          state.scroll = math.max(0, math.min(#state.lines - h + 1,
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

    elseif id == "leftCtrl" or id == "rightCtrl" then
      state.status = "S:save  E:exit"
      menu = true

    end
  end
end

term.clear()
while run do
  term.setCursorBlink(false)
  redraw()
  term.setCursorBlink(true)
  if menu then
    processMenuInput()
  else
    processInput()
  end
end
