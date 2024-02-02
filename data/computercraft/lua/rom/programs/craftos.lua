-- CraftOS compatibility, in theory

local rc = require("rc")
local settings = require("settings")

if not settings.get("bios.compat_mode") then
  error("compatibility mode is disabled", 0)
end

if os.version then
  error("you are already in compatibility mode", 0)
end

local libs = {
  "peripheral", "fs", "settings", "http", "term", "colors", "multishell",
  "keys", "parallel", "shell", "textutils", "window", "paintutils"
}

local move = {
  "queueEvent", "startTimer", "cancelTimer", "setAlarm", "cancelAlarm", "getComputerID",
  "computerID", "getComputerLabel", "setComputerLabel", "computerLabel", "day", "epoch",
  "pullEvent", "sleep"
}

local nEnv = setmetatable({}, {__index=_G})
nEnv.os = setmetatable({}, {__index=os})

for i=1, #libs, 1 do
  nEnv[libs[i]] = select(2, pcall(require, libs[i]))
end

for i=1, #move do
  nEnv.os[move[i]] = rc[move[i]]
end

function nEnv.printError(text)
  io.stderr:write(text, "\n")
end

nEnv.write = rc.write

nEnv.unpack = table.unpack
if rc.lua51 then
  for k, v in pairs(rc.lua51) do
    nEnv[k] = v
  end
end

nEnv.read = nEnv.term.read
nEnv.sleep = nEnv.os.sleep

function nEnv.os.version()
  return "CraftOS 1.8"
end

local func, err = loadfile("/rc/programs/shell.lua", "t", nEnv)
if not func then error(err, 0) end
func()
