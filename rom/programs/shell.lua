-- rc.shell

local term = require("term")
local shell = require("shell")
local write = require("write")
local colors = require("colors")
local printError = require("printError")

term.setCursorPos(1,1)
term.clear()

term.setTextColor(colors.yellow)
print(os.version())

term.setTextColor(colors.white)

shell.init()

local aliases = {
  ls = "list",
  dir = "list"
}

for k, v in pairs(aliases) do
  shell.setAlias(k, v)
end

while true do
  term.setTextColor(colors.yellow)
  write(shell.dir().."> ")
  term.setTextColor(colors.white)

  local text = term.read()
  if #text > 0 then
    local ok, err = shell.run(text)
    if not ok then
      printError(err)
    end
  end
end
