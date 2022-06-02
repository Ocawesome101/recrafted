-- lua REPL

local term = require("term")
local colors = require("colors")
local pretty = require("cc.pretty")
local printError = require("printError")

local env = setmetatable({}, {__index=_G})

local run = true
function env.exit() run = false end

term.setTextColor(colors.yellow)

print("Recrafted Lua REPL.\nCall exit() to exit.")

local history = {}
while run do
  term.setTextColor(colors.white)
  io.write("lua> ")
  local data = term.read(nil, history)
  history[#history+1] = data

  local ok, err = load("return " .. data, "=stdin", "t", env)
  if not ok then
    ok, err = load(data, "=stdin", "t", env)
  end

  if ok then
    local result = table.pack(pcall(ok))
    if not result[1] then
      printError(result[2])
    elseif result.n > 1 then
      for i=2, result.n, 1 do
        pretty.pretty_print(result[i])
      end
    end
  else
    printError(err)
  end
end
