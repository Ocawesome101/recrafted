-- cc.strings

local rc = require("rc")
local strings = {}

function strings.wrap(text, width)
  rc.expect(1, text, "string")
  rc.expect(2, width, "number", "nil")

  width = width or rc.term.getSize()

  local whitespace = "[ \t\n\r]"
  local splitters = "[ %=%+]"
  local ws_sp = whitespace:sub(1,-2) .. splitters:sub(2)

  local odat = ""

  local len = 0
  for c in text:gmatch(".") do
    odat = odat .. c
    len = len + 1

    if c == "\n" then
      len = 0

    elseif len >= width then
      local last = odat:reverse():find(splitters)
      local last_nl = odat:reverse():find("\n") or 0
      local indt = odat:sub(-last_nl + 1):match("^ *") or ""

      if last and last < math.floor(width / 4) and last > 1 and
          not c:match(ws_sp) then
        odat = odat:sub(1, -last) .. "\n" .. indt .. odat:sub(-last + 1)
        len = last + #indt - 1

      else
        odat = odat .. "\n" .. indt
        len = #indt
      end
    end
  end

  if odat:sub(-1) ~= "\n" then odat = odat .. "\n" end

  return odat
end

function strings.ensure_width(line, width)
  rc.expect(1, line, "string")
  rc.expect(2, width, "number", "nil")
  width = width or rc.term.getSize()

  return (line .. (" "):rep(width - #line)):sub(1, width)
end

return strings
