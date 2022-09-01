-- cc.strings

local term = require("term")
local expectlib = require("cc.expect")
local expect = expectlib.expect
local field = expectlib.field
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

function strings.wrappedWriteElements(elements, width, doHalves, handler)
  expect(1, elements, "table")
  expect(2, width, "number")
  expect(3, doHalves, "boolean", "nil")
  expect(4, handler, "table")

  field(handler, "newline", "function")
  field(handler, "append", "function")
  field(handler, "getX", "function")

  for i=1, #elements, 1 do
    local e = elements[i]

    if e.type == "nl" then
      for _=1, #e.text do handler.newline() end

    elseif e.type == "ws" then
      local x = handler.getX()

      if x + #e.text > width + 1 then
        handler.newline()

      else
        handler.append(e.text)
      end

    elseif e.type == "word" then
      local x = handler.getX()
      local half = math.ceil(#e.text / 2)

      if x + #e.text > width + 1 then
        if doHalves and x + half < width and #e.text > width/2 then
          local halfText = e.text:sub(1, math.floor(#e.text / 2)) .. "-"
          e.text = e.text:sub(#halfText)
          handler.append(halfText)
          handler.newline()

        elseif x > 1 then
          handler.newline()
        end
      end

      handler.append(e.text)
    end
  end
end

function strings.wrap(text, width, doHalves)
  expect(1, text, "string")
  expect(2, width, "number", "nil")
  expect(3, doHalves, "boolean", "nil")

  width = width or term.getSize()

  local lines = { "" }
  local elements = strings.splitElements(text, width)

  strings.wrappedWriteElements(elements, width, doHalves, {
    newline = function()
      lines[#lines+1] = ""
    end,

    append = function(newText)
      lines[#lines] = lines[#lines] .. newText
    end,

    getX = function()
      return #lines[#lines]
    end
  })

  return lines
end

function strings.ensure_width(line, width)
  expect(1, line, "string")
  expect(2, width, "number", "nil")
  width = width or term.getSize()

  return (line .. (" "):rep(width - #line)):sub(1, width)
end

return strings
