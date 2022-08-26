-- New scheduler.
-- Tabs are integral to the design of this scheduler;  Multishell cannot
-- be disabled.

local expect = require("cc.expect")
local copy = require("rc.copy").copy

local tabs = {}
local threads = {}

local api = {}

function api.launch(file, name, tab)
  expect(1, file, "string")
  name = expect(2, name, "string", "nil") or file
  tab = expect(3, tab, "number", "nil") or 1

  local env = copy(tabs[])
end

function api.start()
  api.start = nil

  while #tabs > 0 do
  end
end

return api
