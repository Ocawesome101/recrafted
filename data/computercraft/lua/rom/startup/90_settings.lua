-- setting definitions

local settings = require("settings")

settings.define("list.show_hidden", {
  description = "Show hidden files in list's output",
  type = "boolean",
  default = false
})

settings.define("bios.compat_mode", {
  description = "Attempt some CraftOS compatibility by injecting APIs into _G.",
  type = "boolean",
  default = false
})

settings.define("shell.tracebacks", {
  description = "Show error tracebacks in the shell.",
  type = "boolean",
  default = false
})

settings.define("edit.scroll_offset", {
  description = "How many lines to keep between the cursor and the screen edge.",
  type = "number",
  default = 3
})

settings.define("edit.force_highlight", {
  description = "Whether to use the highlighting editor, even on basic computers.",
  type = "boolean",
  default = false
})

settings.define("edit.scroll_factor", {
  description = "Related to how many lines the editor should jump at a time when scrolling. Determined by term_height/scroll_factor.  Adjust this for performance.",
  type = "number",
  default = 8
})

settings.define("edit.color_separator", {
  description = "What color separating characters (e.g. ()[];{}) should be.",
  type = "string",
  default = "lightBlue"
})

settings.define("edit.color_operator", {
  description = "What color operators (e.g. +-/*) should be.",
  type = "string",
  default = "lightGray"
})

settings.define("edit.color_keyword", {
  description = "What color keywords (e.g. local, for, if) should be.",
  type = "string",
  default = "orange"
})

settings.define("edit.color_boolean", {
  description = "What color booleans (true/false) should be.",
  type = "string",
  default = "purple"
})

settings.define("edit.color_comment", {
  description = "What color comments should be.",
  type = "string",
  default = "gray"
})

settings.define("edit.color_global", {
  description = "What color globals (e.g. print, require) should be.",
  type = "string",
  default = "lime"
})

settings.define("edit.color_string", {
  description = "What color strings should be.",
  type = "string",
  default = "red"
})

settings.define("edit.color_number", {
  description = "What color numbers (e.g. 2, 0xF3, 0.42) should be.",
  type = "string",
  default = "magenta"
})

settings.define("bios.restrict_globals", {
  description = "Disallow global variables",
  type = "boolean",
  default = false
})

settings.define("bios.parallel_startup", {
  description = "Run startup scripts from /startup in parallel",
  type = "boolean",
  default = false
})

settings.load()
