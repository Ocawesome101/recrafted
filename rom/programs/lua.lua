-- lua REPL

local term = require("term")
local colors = require("colors")
local printError = require("printError")

local env = setmetatable({}, {__index=_G})

local run = true
function env.exit() run = false end

term.setTextColor(colors.yellow)

print("Recrafted Lua REPL.\n\z
Call exit() to exit.")

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
    print(select(2, pcall(ok)))
  else
    printError(err)
  end
end
