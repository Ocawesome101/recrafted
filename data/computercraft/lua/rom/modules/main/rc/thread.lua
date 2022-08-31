-- New scheduler.
-- Tabs are integral to the design of this scheduler;  Multishell cannot
-- be disabled.

local rc = require("rc")
local fs = require("fs")
local window = require("window")
local expect = require("cc.expect")
local colors = require("colors")
local copy = require("rc.copy").copy
local term = require("term")
local getfenv = rc.lua51.getfenv

local tabs = { {} }
local threads = {}
local current, native

local focused = 1

local api = {}

function api.launchTab(x, name)
  expect(1, x, "string", "function")
  name = expect(2, name, "string", "nil") or tostring(x)

  local newTab = {
    term = window.create(native, 1, 1, native.getSize()),
    id = #tabs + 1
  }

  tabs[newTab.id] = newTab

  local _f = focused
  focused = newTab.id
  local id = (type(x) == "string" and api.load or api.spawn)(x, name)
  focused = _f

  return newTab.id, id
end

function api.setFocusedTab(f)
  expect(1, f, "number")
  if tabs[focused] then focused = f end
  return not not tabs[f]
end

function api.getFocusedTab()
  return focused
end

function api.getCurrentTab()
  return current.tab.id
end

function api.load(file, name)
  expect(1, file, "string")
  name = expect(2, name, "string", "nil") or file

  local env = copy(current and current.env or _G, package.loaded)

  local func, err = loadfile(file, "t", env)
  if not func then
    return nil, err
  end

  return api.spawn(func, name, tabs[focused])
end

function api.spawn(func, name, _)
  expect(1, func, "function")
  expect(2, name, "string")

  local new = {
    name = name,
    coro = coroutine.create(function()
      assert(xpcall(func, debug.traceback))
    end),
    vars = setmetatable({}, {__index = current and current.vars}),
    env = getfenv(func),
    tab = _ or tabs[focused],
    id = #threads + 1,
    dir = current and current.dir or "/"
  }

  new.tab[new.id] = true
  threads[new.id] = new

  new.tab.name = name

  return new.id
end

function api.exists(id)
  expect(1, id, "number")
  return not not threads[id]
end

function api.id()
  return current.id
end

function api.dir()
  return current.dir or "/"
end

function api.setDir(dir)
  expect(1, dir, "string")

  if not fs.exists(dir) then
    return nil, "that directory does not exist"

  elseif not fs.isDir(dir) then
    return nil, "not a directory"
  end

  current.dir = dir
end

function api.vars()
  return current.vars
end

function api.getTerm()
  return current and current.tab and current.tab.term or term.native()
end

function api.setTerm(new)
  if tabs[focused] then
    local old = tabs[focused].term
    tabs[focused].term = new
    return old
  end
end

local function getName(tab)
  local highest = 0

  for k in pairs(tab) do
    if type(k) == "number" then highest = math.max(highest, k) end
  end

  return threads[highest] and threads[highest].name or "???"
end

function api.info()
  local running = {}
  for i, thread in pairs(threads) do
    running[#running+1] = { id = i, name = thread.name, tab = thread.tab.id }
  end

  table.sort(running, function(a,b) return a.id < b.id end)

  return running
end

function api.remove(id)
  expect(1, id, "number", "nil")
  threads[id or current.id] = nil
end

local w, h
local function redraw()
  w, h = native.getSize()

  if #tabs > 1 then
    local len = 1
    native.setCursorPos(1, 1)
    native.setTextColor(colors.black)
    native.setBackgroundColor(colors.gray)
    native.clearLine()

    for i=1, #tabs, 1 do
      local tab = tabs[i]
      local name = " " .. getName(tab) .. " "

      native.setCursorPos(len, 1)
      len = len + #name

      if i == focused then
        native.setTextColor(colors.yellow)
        native.setBackgroundColor(colors.black)
        native.write(name)

      else
        native.setTextColor(colors.black)
        native.setBackgroundColor(colors.gray)
        native.write(name)
      end

      tab.term.setVisible(false)
      tab.term.reposition(1, 2, w, h - 1)
    end

    tabs[focused].term.setVisible(true)

  elseif #tabs > 0 then
    local tab = tabs[1]
    tab.term.reposition(1, 1, w, h)
    tab.term.setVisible(true)
  end
end

local inputEvents = {
  key = true,
  char = true,
  key_up = true,
  mouse_up = true,
  mouse_drag = true,
  mouse_click = true,
  terminate = true,
}

local function processEvent(event)
  local shouldFire = true

  if inputEvents[event[1]] then
    if #event > 3 then -- mouse event

      if #tabs > 1 then
        if event[4] == 1 then
          shouldFire = false
          local curX = 0

          for i=1, #tabs, 1 do
            local tab = tabs[i]
            curX = curX + #getName(tab) + 2

            if event[3] <= curX then
              focused = i
              redraw()
              break
            end
          end

        else
          event[4] = event[4] - 1
        end
      end
    end
  end

  return shouldFire
end

local function cleanTabs()
  for t=#tabs, 1, -1 do
    local tab = tabs[t]

    local count, removed = 0, 0
    for i in pairs(tab) do
      if type(i) == "number" then
        count = count + 1
        if not threads[i] then
          removed = removed + 1
          tab[i] = nil
        end
      end
    end

    if count == removed then
      table.remove(tabs, t)
    end
  end

  for i=1, #tabs, 1 do
    tabs[i].id = i
  end

  focused = math.max(1, math.min(#tabs, focused))
end

function api.start()
  api.start = nil

  native = term.native()
  api.launchTab("/rom/programs/shell.lua", "shell")

  while #tabs > 0 and next(threads) do
    cleanTabs()
    redraw()
    local event = table.pack(coroutine.yield())

    if processEvent(event) then
      for tid, thread in pairs(threads) do
        if thread.tab == tabs[focused] or not inputEvents[event[1]] then
          current = thread
          local result = table.pack(coroutine.resume(thread.coro,
            table.unpack(event, 1, event.n)))

          if not result[1] then
            io.stderr:write(result[2].."\n")
            threads[tid] = nil

          elseif coroutine.status(thread.coro) == "dead" then
            threads[tid] = nil
          end
        end
      end
    end
  end

  rc.shutdown()
end

return api
