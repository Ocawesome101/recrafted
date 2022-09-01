-- rc.help

local fs = require("fs")
local thread = require("rc.thread")
local expect = require("cc.expect").expect
local completion = require("cc.completion")

local help = {}
help._DEFAULT_PATH = "/rc/help"

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

  topic = topic

  for directory in help.path():gmatch("[^:]+") do
    local try = fs.combine(directory, topic .. ".hlp")

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
      topics[#topics+1] = _topics[i]:gsub("%.hlp$", "")
    end
  end

  return topics
end

function help.completeTopic(prefix)
  local topics = help.topics()
  table.sort(topics, function(a, b) return #a < #b end)

  return completion.choice(prefix, topics)
end

local directives = {
  color = function(c)
    return require("colors")[c or "white"]
  end,
  ["break"] = function()
    return "\n"
  end
}

function help.loadTopic(name)
  local path = help.lookup(name)
  if not path then return end

  local handle = io.open(path, "r")
  local data = {}

  local lastWasText = false
  for line in handle:lines() do
    if line:sub(1,2) == ">>" then
      lastWasText = false
      local words = {}
      for word in line:sub(3):gmatch("[^ ]+") do
        words[#words+1] = word
      end

      if directives[words[1]] then
        data[#data+1] = directives[words[1]](table.unpack(words, 2))
      end

    else
      if lastWasText then
        data[#data+1] = "\n"
      end
      lastWasText = true
      data[#data+1] = line
    end
  end

  handle:close()

  return data
end

return help
