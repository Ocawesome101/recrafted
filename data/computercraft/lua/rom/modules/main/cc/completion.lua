-- cc.completion

local expect = require("cc.expect").expect
local settings = require("settings")
local peripheral = require("peripheral")

local c = {}

local function splitLastWord(text)
  local last = #text - (text:reverse():find(" ") or #text)
  return text:sub(last + 1)
end

-- choices and options!
function c.choice(text, choices, add_space)
  expect(1, text, "string")
  expect(2, choices, "table")
  expect(3, add_space, "boolean", "nil")

  local last_word = splitLastWord(text)
  local options = {}

  for i=1, #choices, 1 do
    if choices[i]:sub(1, #last_word) == last_word then
      options[#options+1] = choices[i]:sub(#last_word+1) ..
        (add_space and " " or "")
    end
  end

  return options
end

function c.peripheral(text, add_space)
  return c.choice(text, peripheral.getNames(), add_space)
end

local sides = {"front", "back", "top", "bottom", "left", "right"}
function c.side(text, add_space)
  return c.choice(text, sides, add_space)
end

function c.setting(text, add_space)
  return c.choice(text, settings.getNames(), add_space)
end

return c
