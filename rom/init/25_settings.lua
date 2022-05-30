-- setting definitions

local term = require("term")
local settings = require("settings")

settings.define("list.show_hidden", {
  description = "Show hidden files in list's output",
  type = "boolean",
  default = false
})

settings.define("bios.use_multishell", {
  description = "Use multishell",
  type = "boolean",
  default = term.isColor()
})

settings.define("bios.compat_mode", {
  description = "Attempt some CraftOS compatibility by injecting APIs into _G",
  type = "boolean",
  default = false
})

settings.define("shell.tracebacks", {
  description = "Show error tracebacks in the shell",
  type = "boolean",
  default = false
})

settings.define("edit.scroll_offset", {
  description = "How many lines to keep between the cursor and the screen edge",
  type = "number",
  default = 3
})

settings.load()
