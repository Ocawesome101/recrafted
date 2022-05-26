-- lua REPL

local term = require("term")
local write = require("write")
local printError = require("printError")

local env = setmetatable({}, {__index=_G})

local run = true
function env.exit() run = false end

while run do
  write("lua> ")
  local data = term.read()

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
