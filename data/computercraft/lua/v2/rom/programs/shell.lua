-- rc.shell

local rc = require("rc")
local fs = require("fs")
local term = require("term")
local shell = require("shell")
local colors = require("colors")
local thread = require("rc.thread")
local textutils = require("textutils")

textutils.coloredPrint(colors.yellow, rc.version(), colors.white)

thread.vars().parentShell = thread.id()
shell.init()

local id = rc.startTimer(0)

repeat
  local e, i = rc.pullEvent()
  if e == "init" then
    if fs.exists("/startup.lua") then
      local ok, err = pcall(dofile, "/startup.lua")
      if not ok and err then
        io.stderr:write(err, "\n")
      end
    end
  end
until i == id

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

local completions = "/recrafted/completions"
for _, prog in ipairs(fs.list(completions)) do
  dofile(fs.combine(completions, prog))
end

local history = {}
while true do
  term.setTextColor(colors.yellow)
  term.setBackgroundColor(colors.black)
  rc.write(shell.dir().."> ")
  term.setTextColor(colors.white)

  local text = term.read(nil, history, shell.complete)
  if #text > 0 then
    history[#history+1] = text
    local ok, err = shell.run(text)
    if not ok then
      io.stderr:write(err, "\n")
    end
  end
end
