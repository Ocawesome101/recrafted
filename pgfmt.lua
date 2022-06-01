#!/usr/bin/env lua
-- format web pages into HTML documents.

local args = table.pack(...)

if #args < 2 then
  io.stderr:write([[
usage: pgfmt TITLE DOCUMENT OUTPUT

Basic HTML document formatter.

OUTPUT defaults to stdout.  If the STYLESHEET environment variable is set it will be used instead of "style.css" for the output's stylesheet.
]])
  os.exit(1)
end

local header = [[
<!DOCTYPE html>

<link rel="stylesheet" href="]] .. (os.getenv("STYLESHEET") or "style.css") .. [[">

<html>
  <title>]] .. args[1] .. [[</title>
  <body>]]

local footer = [[
  </body>
</html>
]]

local patterns = {
  -- format: *class{text}
  {"%*(%a+)(%b{})", function(a, b)
    return "<span class='" .. a .. "'>" .. b:sub(2,-2) .. "</span>" end},
  -- format: @text{link}
  {"@([^{]+)(%b{})", function(a, b)
    return "<a href='" .. b:sub(2, -2) .. "'>" .. a .. "</a>" end},
  -- format: #{image_link}
  {"#(%b{})", function(a) return "<img src='" .. a:sub(2,-2) .. "'>" end},
  -- format: %{paragraph_text}
  {"%%(%b{})", function(a) return "<p>" .. a:sub(2, -2):gsub("\n","<br>") .. "</p>" end},
  -- replace ' ' with '&nbsp;'
  {"  +", function(a)return ("&nbsp;"):rep(#a) end},
}

local handle = assert(io.open(args[2], "r"))
local data = handle:read("a")
handle:close()

local outhandle = args[3] and assert(io.open(args[3], "w")) or io.stdout

for i=1, #patterns, 1 do
  while data:match(patterns[i][1]) do
    data = data:gsub(patterns[i][1], patterns[i][2])
  end
end

data = header .. data .. footer
outhandle:write(data)
pcall(outhandle.close, outhandle)
