-- rc.rednet

local expect = require("cc.expect").expect
local peripheral = require("peripheral")
local rc = require("rc")
local thread = require("rc.thread")

local rednet = {
  CHANNEL_BROADCAST = 65535,
  CHANNEL_REPEAT    = 65533,
  MAX_ID_CHANNELS   = 65500,
}

local opened = {}
function rednet.open(modem)
  expect(1, modem, "string")
  peripheral.call(modem, "open", rc.computerID())
  peripheral.call(modem, "open", rednet.CHANNEL_BROADCAST)
  opened[modem] = true
end

local function call(method, modem, erase, passids, ...)
  local ret = false
  if modem then
    if erase then opened[modem] = false end
    if passids then
      ret = ret or peripheral.call(modem, method, rc.computerID(), ...)
      ret = ret or peripheral.call(modem, method, rednet.CHANNEL_BROADCAST, ...)
    else
      ret = peripheral.call(modem, method, ...)
    end

  else
    for k in pairs(opened) do
      ret = ret or call(method, k, erase, passids, ...)
    end
  end
  return ret
end

function rednet.close(modem)
  expect(1, modem, "string", "nil")
  return call("close", modem, true, true)
end

function rednet.isOpen(modem)
  expect(1, modem, "string", "nil")
  return call("isOpen", modem, false, true)
end

---Composes the rednet message, to match the layout in the receive end.
---Else, the rednet will not recognise the message as it's own.
---@param to number The recipient or the port
---@param message any The actual message, whichever it is.
---@param protocol? string Optional protocol for filtering
local function compose(to, message, protocol)
  return { "rednet_message", to, message, protocol }
end

function rednet.send(to, message, protocol)
  expect(1, to, "number")
  expect(2, message, "string", "table", "number", "boolean")
  expect(3, protocol, "string", "nil")

  call("transmit", nil, false, false, rednet.CHANNEL_BROADCAST,
    rc.computerID(), compose(to, message, protocol))
  return rednet.isOpen()
end

function rednet.broadcast(message, protocol)
  expect(1, message, "string", "table", "number", "boolean")
  expect(2, protocol, "string", "nil")
  call("transmit", nil, false, false, rednet.CHANNEL_BROADCAST,
    rednet.CHANNEL_BROADCAST, compose(rednet.CHANNEL_BROADCAST, message, protocol))
end

function rednet.receive(protocol, timeout)
  expect(1, protocol, "string", "nil")
  timeout = expect(2, timeout, "number", "nil")

  local timer
  if timeout then
    timer = rc.startTimer(timeout)
  end

  while true do
    local event = table.pack(rc.pullEvent())
    if event[1] == "timer" and event[2] == timer then return end
    if event[1] == "rednet_message" and (event[4] == protocol or
        not protocol) then
      return table.unpack(event, 2)
    end
  end
end

local running = false
function rednet.run()
  if running then
    error("rednet is already running")
  end

  running = true

  while true do
    local event = table.pack(rc.pullEvent())

    if event[1] == "modem_message" then
      local message = event[5]
      if type(message) == "table" then
        local signature, recipient, payload, protocol = table.unpack(message)
        if signature == "rednet_message" and (recipient == rc.computerID() or
            recipient == rednet.CHANNEL_BROADCAST) then
          rc.queueEvent("rednet_message", event[3], payload, protocol)
        end
      end
    end
  end
end

-- Start the event loop lazily
if not running then
  thread.spawn(rednet.run, "rednet_run")
end

return rednet
