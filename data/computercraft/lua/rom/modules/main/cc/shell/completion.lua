-- cc.shell.completion
-- XXX incompatible: functions do not accept a 'shell' argument

local completion = require("cc.completion")
local expect = require("cc.expect").expect
local shell = require("shell")
local fs = require("fs")

local c = {}

function c.file(text)
  expect(1, text, "string")
  
end

function c.dir(text)
  expect(1, text, "string")
end

return c
