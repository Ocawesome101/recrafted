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

if not shell.__has_run_startup then
  shell.__has_run_startup = true
  if fs.exists("/startup.lua") then
    local ok, err = pcall(dofile, "/startup.lua")
    if not ok and err then
      io.stderr:write(err, "\n")
    end
  end

  if fs.exists("/startup") and fs.isDir("/startup") then
    local files = fs.list("/startup/")
    table.sort(files)

    for f=1, #files, 1 do
      local ok, err = pcall(dofile, "/startup/"..files[f])
      if not ok and err then
        io.stderr:write(err, "\n")
      end
    end
  end
end

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

local completions = "/rc/completions"
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
    if not ok and err then
      io.stderr:write(err, "\n")
    end
  end
end
