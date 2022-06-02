-- rc.shell

local fs = require("fs")
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

local completions = fs.combine(require("rc")._ROM_DIR, "completions")
for _, prog in ipairs(fs.list(completions)) do
  dofile(fs.combine(completions, prog))
end

if fs.exists("/startup.lua") then
  local ok, err = pcall(dofile, "/startup.lua")
  if not ok and err then
    printError(err)
  end
end

while true do
  term.setTextColor(colors.yellow)
  term.setBackgroundColor(colors.black)
  write(shell.dir().."> ")
  term.setTextColor(colors.white)

  local text = term.read(nil, nil, shell.complete)
  if #text > 0 then
    local ok, err = shell.run(text)
    if not ok then
      printError(err)
    end
  end
end
