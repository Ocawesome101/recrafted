-- rc.gps

error("gps is not fully implemented", 0)

local expect = require("cc.expect").expect
local rednet = require("rednet")

local gps = {}
gps.CHANNEL_GPS = 65534

function gps.locate(timeout, debug)
  timeout = expect(1, timeout, "number", "nil") or 2
  expect(2, debug, "boolean", "nil")

  rednet.broadcast()
end

return gps
