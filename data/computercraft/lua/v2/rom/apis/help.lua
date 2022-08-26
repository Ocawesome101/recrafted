-- rc.help

local fs = require("fs")
local thread = require("rc.thread")
local expect = require("cc.expect").expect
local completion = require("cc.completion")

local help = {}
help._DEFAULT_PATH = "/recrafted/help"

function help.init()
  local vars = thread.vars()
  vars.help = vars.help or help._DEFAULT_PATH
end

function help.path()
  return thread.vars().help or help._DEFAULT_PATH
end

function help.setPath(new)
  expect(1, new, "string")
  thread.vars().help = new
end

function help.lookup(topic)
  expect(1, topic, "string")

  topic = topic .. ".octf"

  for directory in help.path():gmatch("[^:]+") do
    local try = fs.combine(directory, topic)

    if fs.exists(try) then
      return try
    end
  end
end

function help.topics()
  local topics = {}

  for directory in help.path():gmatch("[^:]+") do
    local _topics = fs.list(directory)
    for i=1, #_topics, 1 do
      topics[#topics+1] = _topics[i]:gsub("%.octf$", "")
    end
  end

  return topics
end

function help.completeTopic(prefix)
  local topics = help.topics()
  table.sort(topics, function(a, b) return #a < #b end)

  return completion.choice(prefix, topics)
end

return help
