-- A much better editor.

local term = require("term")
local colors = require("colors")
local settings = require("settings")

local args = {...}

local type_colors = {
  separator = colors[settings.get("edit.color_separator") or "lightBlue"],
  operator = colors[settings.get("edit.color_operator") or "red"],
  keyword = colors[settings.get("edit.color_keyword") or "orange"],
  boolean = colors[settings.get("edit.color_boolean") or "purple"],
  comment = colors[settings.get("edit.color_comment") or "gray"],
  string = colors[settings.get("edit.color_string") or "red"],
  global = colors[settings.get("edit.color_global") or "lime"],
  number = colors[settings.get("edit.color_number") or "magenta"]
}

local lines = {}
local linesDraw = {}
local run, menu = true, false
local cx, cy = 1, 1
local scroll = 0
local hscroll = 0
local unsaved
local status = "Press Ctrl for menu"

local win = require("window").create(term.current(), 1, 1, term.getSize())

local function redraw()
  local w, h = term.getSize()
  win.reposition(1, 1, w, h)

  win.setVisible(false)

  for i=1, h - 1, 1 do
    local line = linesDraw[scroll + i]
    win.setCursorPos(1, i)
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

  win.setVisible(true)
end

local syntax = require("edit.syntax").new("/rc/modules/main/edit/syntax/lua.lua")

local function rehighlight()
  local line = {}
  linesDraw = {}
  for token, ttype in syntax(table.concat(lines, "\n")) do
    if token == "\n" then
      linesDraw[#linesDraw+1] = line
      line = {}

    else
      line[#line+1] = type_colors[ttype] or colors.white
      line[#line+1] = token
    end
  end
end

if args[1] then
  for line in io.lines(args[1]) do
    lines[#lines+1] = line
  end
end

rehighlight()

while run do
  redraw()
  if menu then
    processMenuInput()
  else
    processInput()
  end
end
