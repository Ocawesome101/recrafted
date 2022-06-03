-- rc.rednet

local expect = require("cc.expect").expect
local peripheral = require("peripheral")

local rednet = {
  CHANNEL_BROADCAST = 65535,
  CHANNEL_REPEAT    = 65533,
  MAX_ID_CHANNELS   = 65500,
}

local opened = {}
function rednet.open(modem)
  expect(1, modem, "string")
  peripheral.call(modem, "open", os.computerID())
  peripheral.call(modem, "open", rednet.CHANNEL_BROADCAST)
  opened[modem] = true
end

local function call(method, modem, erase, passids, ...)
  local ret = false
  if modem then
    if erase then opened[modem] = false end
    if passids then
      ret = ret or peripheral.call(modem, method, os.computerID(), ...)
      ret = ret or peripheral.call(modem, method, rednet.CHANNEL_BROADCAST, ...)
    else
      ret = peripheral.call(modem, method, ...)
    end

  else
    for k in pairs(opened) do
      ret = ret or call(k, method, erase, passids, ...)
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

function rednet.send(to, message, protocol)
  expect(1, to, "number")
  expect(2, message, "string", "table", "number", "boolean")
  expect(3, protocol, "string", "nil")

  if type(message) == "table" then
    if protocol then table.insert(message, 1, protocol) end
    table.insert(message, 1, "rednet_message")
  else
    message = {"rednet_message", to, message, protocol}
  end
  call("transmit", nil, false, false, rednet.CHANNEL_BROADCAST,
    os.computerID(), message)
  return rednet.isOpen()
end

function rednet.broadcast(message, protocol)
  expect(1, message, "string", "table", "number", "boolean")
  expect(2, protocol, "string", "nil")
  call("transmit", nil, false, false, rednet.CHANNEL_BROADCAST,
    rednet.CHANNEL_BROADCAST, message)
end

function rednet.receive(protocol, timeout)
  expect(1, protocol, "string", "nil")
  timeout = expect(2, timeout, "number", "nil") or math.huge

  local timer
  if timeout then
    timer = os.startTimer(timer)
  end

  while true do
    local event = table.pack(os.pullEvent())
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
    local event = table.pack(os.pullEvent())
    if event[1] == "modem_message" then
      local message = event[5]
      if type(message) == "table" then
        if message[1] == "rednet_message" and (message[2] == os.computerID() or
            message[2] == rednet.CHANNEL_BROADCAST) then
          os.queueEvent("rednet_message", event[3], message[2], message[3])
        end
      end
    end
  end
end

return rednet
