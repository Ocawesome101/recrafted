-- clean up 'os'

local rc = ...

local thread = require("thread")

rc.queueEvent = os.queueEvent

function os.pullEventRaw(filter)
  rc.expect(1, filter, "string", "nil")
  local event
  repeat
    event = table.pack(coroutine.yield())
  until event[1] == filter or not filter
  return table.unpack(event, 1, event.n)
end

local foreground = {
  key = true,
  char = true,
  key_up = true,
  mouse_up = true,
  terminate = true,
  mouse_drag = true,
  mouse_click = true,
  mouse_scroll = true
}

function os.pullEvent(filter)
  rc.expect(1, filter, "string", "nil")
  local event
  repeat
    event = table.pack(coroutine.yield())

    if foreground[event[1]] then
      if thread.id() == thread.groupForeground() then
        if event[1] == "terminate" then
          error("terminated", 0)
        end

      else
        event[1] = string.char(math.random(0, 255))
      end

    else
      event[1] = string.char(math.random(0,255))
    end
  until event[1] == filter or not filter
  return table.unpack(event, 1, event.n)
end

function rc.sleep(n)
  local id = os.startTimer(n)
  repeat
    local _, _id = os.pullEvent("timer")
  until _id == id
  return true
end

os.sleep = rc.sleep
os.version = rc.version
os.exit = require("shell").exit
