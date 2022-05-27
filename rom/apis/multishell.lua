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

local currentTerm = term.current()
local w, h = term.getSize()

local tab_id = 0
local tabs = {}
local focused = 0
local current = 0

local function redraw()
  for i=#tabs, 1, -1 do
    if not thread.exists(tabs[i].pid) then
      table.remove(tabs, i)
    end
  end

  for i=1, #tabs, 1 do
    tabs[i].id = i
  end

  if not tabs[focused] then
    focused = next(tabs) or focused
  end

  if #tabs > 1 then
    currentTerm.setCursorPos(1, 1)
    currentTerm.setTextColor(colors.black)
    currentTerm.setBackgroundColor(colors.gray)
    currentTerm.write(string.rep(" ", w))
    currentTerm.setCursorPos(1, 1)
    for _, tab in ipairs(tabs) do
      if tab.id == focused then
        currentTerm.setTextColor(colors.yellow)
        currentTerm.setBackgroundColor(colors.black)
        tab.term.setVisible(true)
      else
        currentTerm.setTextColor(colors.black)
        currentTerm.setBackgroundColor(colors.gray)
        tab.term.setVisible(false)
      end
      currentTerm.write(" "..tab.title.." ")
    end
    for _, tab in ipairs(tabs) do
      tab.term.reposition(1, 2, w, h - 1)
    end
  elseif #tabs == 1 then
    local _, tab = next(tabs)
    tab.term.reposition(1, 1, w, h)
    tab.term.setVisible(true)
    tab.term.redraw()
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
    focused = tab.id
    current = tab.id
    sh.exec(path, table.unpack(args, 1, args.n))
  end

  if rc.lua51 and env then rc.lua51.setfenv(exec, env) end

  tab_id = tab_id + 1
  local tabcount = #tabs
  tab = {
    title = fs.getName(path),
    term = window.create(currentTerm, 1, tabcount > 1 and 2 or 1,
      w, h - (tabcount > 1 and 1 or 0), false),
    pid = thread.add(exec, path),
    id = tab_id
  }

  tabs[tab_id] = tab
  switch(tab_id)

  return tab_id
end

return api
