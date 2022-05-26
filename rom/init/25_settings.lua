-- setting definitions

local settings = require("settings")

settings.define("list.show_hidden", {
  description = "Show hidden files in list's output",
  type = "boolean",
  default = false
})

settings.load()
