-- CraftOS compatibility, in theory

local libs = {
  "peripheral", "fs", "settings", "http", "term", "colors", "multishell",
  "keys", "parallel", "settings", "shell", "textutils", "window"
}

for i=1, #libs, 1 do
  _G[libs[i]] = require(libs[i])
end

shell.run(...)
