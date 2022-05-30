-- Multishell

local api = {}
local fs = require("fs")
local rc = require("rc")
local keys = require("keys")
local term = require("term")
local colors = require("colors")
local expect = require("cc.expect").expect
local thread = require("thread")
local window = require("window")
local textutils = require("textutils")

local currentTerm = term.current()
local w, h = term.getSize()

local tabs = {}
local focused = 2
local current = 0

local function redraw()
  w, h = currentTerm.getSize()
  for i=#tabs, 1, -1 do
    if not thread.exists(tabs[i].pid) then
      table.remove(tabs, i)
    end
  end

  for i=1, #tabs, 1 do
    local tab = tabs[i]
    tab.id = i
    while #tab.foreground > 0 and not thread.exists(
        tab.foreground[#tab.foreground]) do
      tab.foreground[#tab.foreground] = nil
    end
  end

  while focused > 1 and not tabs[focused] do
    focused = focused - 1
  end

  if #tabs > 1 then
    currentTerm.setCursorPos(1, 1)
    currentTerm.setTextColor(colors.black)
    currentTerm.setBackgroundColor(colors.gray)
    currentTerm.clearLine()
    currentTerm.setCursorPos(1, 1)
    for _, tab in ipairs(tabs) do
      if tab.id == focused then
        currentTerm.setTextColor(colors.yellow)
        currentTerm.setBackgroundColor(colors.black)
      else
        currentTerm.setTextColor(colors.black)
        currentTerm.setBackgroundColor(colors.gray)
      end
      currentTerm.write(" "..tab.title.." ")
    end

    for _, tab in ipairs(tabs) do
      if tab.id == focused then
        tab.term.setVisible(true)
        api.switchForeground(tab.foreground[#tab.foreground])
      else
        tab.term.setVisible(false)
      end
      tab.term.reposition(1, 2, w, h - 1)
    end
  elseif #tabs == 1 then
    local tab = tabs[1]
    tab.term.reposition(1, 1, w, h)
    tab.term.setVisible(true)
  end
end

local function switch(id)
  if tabs[focused] then
    tabs[focused].term.setVisible(false)
  end
  focused = id
  tabs[id].term.setVisible(true)
  redraw()
end

function api.getFocus()
  return focused
end

function api.setFocus(n)
  expect(1, n, "number")
  if tabs[n] then switch(n) end
  return not not tabs[n]
end

function api.getTitle(n)
  expect(1, n, "number")
  return tabs[n] and tabs[n].name
end

function api.setTitle(n, title)
  expect(1, n, "number")
  expect(2, title, "string")
  if tabs[n] then tabs[n].title = title end
end

function api.getCurrent()
  return current
end

-- programs should use these, NOT the `thread` functions, for tab-specific
-- foregrounding to behave correctly
function api.getForeground()
  if #tabs > 0 then
    local cur = tabs[current]
    return cur.foreground[#cur.foreground]
  else
    return thread.getForeground()
  end
end

function api.pushForeground(pid)
  expect(1, pid, "number")
  if not thread.exists(pid) then return end
  if #tabs > 0 then
    local cur = tabs[current]
    cur.foreground[#cur.foreground+1] = pid
    if current == focused then thread.switchForeground(pid) end
    return true
  else
    return thread.pushForeground(pid)
  end
end

function api.switchForeground(pid)
  expect(1, pid, "number")
  if not thread.exists(pid) then return end
  if #tabs > 0 then
    local cur = tabs[current]
    cur.foreground[#cur.foreground] = pid
    if current == focused then thread.switchForeground(pid) end
    return true
  else
    return thread.pushForeground(pid)
  end
end

local key_events = {
  key = true,
  char = true,
  key_up = true,
}

local mouse_events = {
  mouse_up = true,
  mouse_drag = true,
  mouse_click = true,
  mouse_scroll = true,
}

local raw_yield = coroutine.yield
local alt_is_down = false

local function tryEvent(sig, result)
  local shouldReturn = true

  -- TODO this code feels pretty jank
  if mouse_events[sig] then
    local x, y = result[3], result[4]
    if #tabs > 1 then
      y = y - 1
      if y == 0 then
        shouldReturn = false
        local _x = 0
        for i=1, #tabs, 1 do
          _x = _x + #tabs[i].title + 2
          if x <= _x then
            switch(i)
            break
          end
        end
      end
    end
  elseif sig == "key" or sig == "key_up" then
    if result[2] == keys.leftAlt or result[2] == keys.rightAlt then
      alt_is_down = sig == "key"
    elseif alt_is_down and sig == "key" then
      alt_is_down = false
      if result[2] == keys.left then
        if focused > 1 then
          shouldReturn = false
          switch(focused - 1)
        end
      elseif result[2] == keys.right then
        if focused < #tabs then
          shouldReturn = false
          switch(focused + 1)
        end
      end
    end
  end

  return shouldReturn
end

function api.launch(env, path, ...)
  expect(1, env, "string", "table", "nil")
  if type(env) ~= "string" then expect(2, path, "string") end

  local args
  if type(env) == "string" then
    args = table.pack(path, ...)
    path = env
    env = nil
  else
    args = table.pack(...)
  end

  local tab = {}

  local function yield(...)
    coroutine.yield = raw_yield

    redraw()

    while true do
      local result = table.pack(raw_yield(...))

      local sig = result[1]
      if (not(key_events[sig] or mouse_events[sig])) or focused == tab.id then
        local shouldReturn = tryEvent(sig, result)

        if shouldReturn then
          coroutine.yield = yield
          tab.interact = true
          current = tab.id

          return table.unpack(result, 1, result.n)
        end
      end
    end
  end

  local function exec()
    local sh = require("shell")
    sh.init()
    coroutine.yield = yield
    term.redirect(tab.term)
    current = tab.id

    local ok, err = sh.exec(path, table.unpack(args, 1, args.n))
    if not ok then
      rc.printError(err)
    end

    if not tab.interact then
      textutils.coloredPrint(colors.yellow, "Press any key to continue")
      os.pullEvent("char")
    end
    thread.remove()
  end

  if rc.lua51 and env then rc.lua51.setfenv(exec, env) end

  local tabid = #tabs + 1
  tab = {
    title = fs.getName(path),
    term = window.create(currentTerm, 1, tabid > 2 and 2 or 1,
      w, h - (tabid > 2 and 1 or 0), false),
    pid = thread.add(exec, path),
    interact = false,
    foreground = {},
    id = tabid
  }

  tab.foreground[1] = tab.pid
  tabs[tabid] = tab

  return tabid
end

return api
