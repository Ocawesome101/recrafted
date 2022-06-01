-- rc.shell

local term = require("term")
local shell = require("shell")
local write = require("write")
local colors = require("colors")
local textutils = require("textutils")
local printError = require("printError")

textutils.coloredPrint(colors.yellow, os.version(), colors.white)

shell.init()

local aliases = {
  background = "bg",
  clr = "clear",
  cp = "copy",
  dir = "list",
  foreground = "fg",
  ls = "list",
  mv = "move",
  rm = "delete",
  rs = "redstone",
  sh = "shell",
  ps = "threads"
}

for k, v in pairs(aliases) do
  shell.setAlias(k, v)
end

while true do
  term.setTextColor(colors.yellow)
  term.setBackgroundColor(colors.black)
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
