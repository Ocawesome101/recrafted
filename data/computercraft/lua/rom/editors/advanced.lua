-- A much better editor.

local rc = require("rc")
local keys = require("keys")
local term = require("term")
local colors = require("colors")
local settings = require("settings")
local textutils = require("textutils")

local args = {...}

local type_colors = {
  separator = colors[settings.get("edit.color_separator") or "lightBlue"],
  operator = colors[settings.get("edit.color_operator") or "lightGray"],
  keyword = colors[settings.get("edit.color_keyword") or "orange"],
  boolean = colors[settings.get("edit.color_boolean") or "purple"],
  comment = colors[settings.get("edit.color_comment") or "gray"],
  builtin = colors[settings.get("edit.color_global") or "lime"],
  string = colors[settings.get("edit.color_string") or "red"],
  number = colors[settings.get("edit.color_number") or "magenta"]
}

local lines = {}
local linesDraw = {}
local run, menu = true, false
local cx, cy = 1, 1
local scroll = 0
local hscroll = 0
local scroll_offset = settings.get("edit.scroll_offset") or 3
local scroll_increment = 0
local scroll_factor = settings.get("edit.scroll_factor") or 8
local unsaved, changed = false, true
local file = args[1] or ".new"
local status = "Press Ctrl for menu"

if args[1] then
  local handle = io.open(args[1], "r")

  if handle then
    for line in handle:lines() do
      lines[#lines+1] = line
    end
    handle:close()
  end
end

if not lines[1] then lines[1] = "" end

local win = require("window").create(term.current(), 1, 1, term.getSize())

local function redraw()
  local w, h = term.getSize()

  -- this seems to provide a good responsiveness curve on my machine
  scroll_increment = math.floor(h/scroll_factor)

  win.reposition(1, 1, w, h)

  win.setVisible(false)

  for i=1, h - 1, 1 do
    local line = linesDraw[i]
    win.setCursorPos(1 - hscroll, i)
    win.clearLine()
    if line then
      for t=1, #line, 1 do
        local item = line[t]
        if type(item) == "number" then
          win.setTextColor(item)
        else
          win.write(item)
        end
      end
    end
  end

  win.setCursorPos(1, h)
  win.clearLine()
  win.setTextColor(type_colors.accent or colors.yellow)
  win.write(status)
  win.setTextColor(colors.white)

  win.setCursorPos(math.min(w, cx), cy - scroll)
  win.setCursorBlink(true)

  win.setVisible(true)
end

local syntax = require("edit.syntax")
  .new("/rc/modules/main/edit/syntax/lua.lua")

local function rehighlight()
  local line = {}
  linesDraw = {}
  local _, h = term.getSize()
  local text = table.concat(lines, "\n", scroll+1,
    math.min(#lines, scroll+h+1)) or ""
  for token, ttype in syntax(text) do
    if token == "\n" then
      linesDraw[#linesDraw+1] = line
      line = {}

    else
      repeat
        local bit = token:find("\n")
        local nl = not not bit
        local chunk = token:sub(1, bit or #token)
        token = token:sub(#chunk+1)
        line[#line+1] = type_colors[ttype] or colors.white
        line[#line+1] = chunk
        if nl then
          linesDraw[#linesDraw+1] = line
          line = {}
        end
      until #token == 0
    end
  end

  if #line > 0 then
    linesDraw[#linesDraw+1] = line
  end
end

local function save()
  if file == ".new" then
    local _, h = term.getSize()
    term.setCursorPos(1, h)
    textutils.coloredWrite(colors.yellow, "filename: ")
    file = term.read()
  end

  local handle, err = io.open(file, "w")
  if not handle then
    status = err

  else
    for i=1, #lines, 1 do
      handle:write(lines[i] .. "\n")
    end
    handle:close()

    status = "Saved to " .. file
    unsaved = false
  end
end

local function processInput()
  local event, id = rc.pullEvent()

  local w, h = term.getSize()

  if event == "char" then
    local line = lines[cy]
    unsaved = true

    if cx > #line then
      line = line .. id

    elseif cx == 1 then
      line = id .. line

    else
      line = line:sub(0, cx-1) .. id .. line:sub(cx)
    end

    cx = cx + 1
    lines[cy] = line
    changed = true

  elseif event == "key" then
    id = keys.getName(id)

    if id == "backspace" then
      local line = lines[cy]
      unsaved = true

      if cx == 1 and cy > 1 then
        local previous = table.remove(lines, cy - 1)
        cy = cy - 1
        cx = #previous + 1
        line = previous .. line

      else
        if #line > 0 then
          if cx > #line then
            cx = cx - 1
            line = line:sub(1, -2)

          elseif cx > 1 then
            line = line:sub(0, cx - 2) .. line:sub(cx)
            cx = cx - 1
          end
        end
      end

      lines[cy] = line
      changed = true

    elseif id == "enter" then
      if cx == 1 then
        table.insert(lines, cy, "")

      elseif cx > #lines[cy] then
        table.insert(lines, cy+1, "")

      else
        local line = lines[cy]
        local before, after = line:sub(0, cx - 1), line:sub(cx)
        lines[cy] = before
        table.insert(lines, cy + 1, after)
      end

      cy = cy + 1
      cx = 1

      changed = true

    elseif id == "up" then
      if cy > 1 then
        cy = cy - 1
        if cy - scroll < scroll_offset then
          local old_scroll = scroll
          scroll = math.max(0, scroll - scroll_increment)
          if scroll < old_scroll then
            rehighlight()
          end
        end
      end

      cx = math.min(cx, #lines[cy] + 1)

    elseif id == "down" then
      if cy < #lines then
        cy = math.min(#lines, cy + 1)

        if cy - scroll > h - scroll_offset then
          local old_scroll = scroll
          scroll = math.max(0, math.min(#lines - h + 1,
            scroll + scroll_increment))
          if scroll > old_scroll then
            rehighlight()
          end
        end
      end

      cx = math.min(cx, #lines[cy] + 1)

    elseif id == "left" then
      if cx > 1 then
        cx = cx - 1
      end

      hscroll = math.max(0, cx - w)

    elseif id == "right" then
      if cx < #lines[cy] + 1 then
        cx = cx + 1
      end

      hscroll = math.max(0, cx - w)

    elseif id == "leftCtrl" or id == "rightCtrl" then
      status = "S:save  E:exit"
      menu = true
    end
  end
end

local function processMenuInput()
  local event, id = rc.pullEvent()

  if event == "char" then
    if id:lower() == "e" then
      if unsaved and menu ~= 2 then
        status = "Lose unsaved work? E:yes C:no"
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
      status = "Press Ctrl for menu"
      menu = false
    end
  end
end

while run do
  if changed then rehighlight() changed = false end
  redraw()
  if menu then
    processMenuInput()
  else
    processInput()
  end
end
