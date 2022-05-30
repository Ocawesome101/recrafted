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

function os.pullEvent(filter)
  rc.expect(1, filter, "string", "nil")
  local event
  repeat
    event = table.pack(coroutine.yield())
    if event[1] == "terminate" and thread.id() == thread.getForeground() then
      error("terminated", 0)
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
