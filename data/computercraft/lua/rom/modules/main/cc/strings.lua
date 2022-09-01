-- cc.strings

local term = require("term")
local expect = require("cc.expect").expect
local strings = {}

local function count(...)
  local tab = table.pack(...)
  local n = 0

  for i=1, tab.n, 1 do
    if tab[i] then n = n + 1 end
  end

  return n
end

function strings.splitElements(text, limit)
  expect(1, text, "string")
  expect(2, limit, "number", "nil")

  local tokens = {}

  while #text > 0 do
    local ws = text:match("^[ \t]+")
    local nl = text:match("^\n+")
    local sep = text:match("^[%-%+%*]")
    local word = text:match("^[^ \t\n%-%+%*]+")

    if count(ws, nl, sep, word) > 1 then
      error(("Edge case: %q, %q, %q, %q"):format(ws, nl, sep, word), 0)
    end

    local token = ws or nl or sep or word
    text = text:sub(#token + 1)

    while #token > 0 do
      local ttext = token:sub(1, limit or 65535)
      token = token:sub(#ttext + 1)

      tokens[#tokens+1] = { text = ttext, type = ws and "ws" or nl and "nl"
        or sep and "word" or word and "word" }
    end
  end

  return tokens
end

local function write_word(lines, width, token, begin)
  if token.type == "nl" then
    for _=1, #token.text, 1 do
      lines[#lines + 1] = ""
    end

  elseif token.type == "ws" then
    local line = lines[#lines]
    if #line + #token.text + begin >= width then
      lines[#lines + 1] = ""
    elseif #line + begin > 0 then
      lines[#lines] = line .. token.text
    end

  elseif token.type == "word" then
    local line = lines[#lines]
    local half = math.ceil(#token.text / 2)

    if #line + #token.text + begin > width then
      if #line + begin + half < width and #token.text > width/2 then
        local halfText = token.text:sub(1, math.floor(#token.text / 2)) .. "-"
        lines[#lines] = line .. halfText
        token.text = token.text:sub(#halfText)
      end

      lines[#lines + 1] = token.text

    else
      lines[#lines] = line .. token.text
    end
  end
end
--[[
function strings.wrappedWriteElements(elements, width, handler)
  expect(1, elements, "table")
  expect(2, width, "number", "nil")
  expect(3, handler, "table")

  for i=1, #elements, 1 do
    local e = elements[i]
    if e.type == "nl" then
      for _=1, #e
  end
end--]]

function strings.wrap(text, width, begin)
  expect(1, text, "string")
  expect(2, width, "number", "nil")
  expect(3, begin, "number", "nil")

  width = width or term.getSize()
  begin = begin or 0

  local lines = { "" }
  local tokens = strings.splitElements(text, width)

  for i=1, #tokens, 1 do
    write_word(lines, width, tokens[i], begin)
    if #lines > 1 then begin = 0 end
  end

  return lines
end

function strings.ensure_width(line, width)
  expect(1, line, "string")
  expect(2, width, "number", "nil")
  width = width or term.getSize()

  return (line .. (" "):rep(width - #line)):sub(1, width)
end

return strings
