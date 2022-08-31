-- lua REPL

local term = require("term")
local copy = require("rc.copy").copy
local colors = require("colors")
local pretty = require("cc.pretty")
local textutils = require("textutils")

local env = copy(_G, package.loaded)

local run = true
function env.exit() run = false end

term.setTextColor(colors.yellow)

print("Recrafted Lua REPL.\nCall exit() to exit.")

local history = {}
while run do
  term.setTextColor(colors.white)
  io.write("lua> ")
  local data = term.read(nil, history, function(text)
    return textutils.complete(text, env)
  end)
  if #data > 0 then
    history[#history+1] = data
  end

  local ok, err = load("return " .. data, "=stdin", "t", env)
  if not ok then
    ok, err = load(data, "=stdin", "t", env)
  end

  if ok then
    local result = table.pack(pcall(ok))
    if not result[1] then
      io.stderr:write(result[2], "\n")
    elseif result.n > 1 then
      for i=2, result.n, 1 do
        pretty.pretty_print(result[i])
      end
    end
  else
    io.stderr:write(err, "\n")
  end
end
