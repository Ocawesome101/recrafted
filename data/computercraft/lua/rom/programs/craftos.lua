-- CraftOS compatibility, in theory

local settings = require("settings")

if not settings.get("bios.compat_mode") then
  error("compatibility mode is disabled", 0)
end

local libs = {
  "peripheral", "fs", "settings", "http", "term", "colors", "multishell",
  "keys", "parallel", "shell", "textutils", "window", "paintutils"
}

for i=1, #libs, 1 do
  _G[libs[i]] = select(2, pcall(require, libs[i]))
end

function _G.printError(text)
  io.stderr:write(text, "\n")
end

_G.write = require("rc").write

_G.unpack = table.unpack
for k, v in pairs(require("rc").lua51) do
  _G[k] = v
end
_G.read = term.read

function os.version()
  return "CraftOS 1.8"
end

shell.run("/rc/programs/shell.lua")
