-- rc.octf - the Open ComputerCraft Text Format
-- This is how the included help files are formatted.

local colors = require("colors")
local expect = require("cc.expect").expect
local lib = {}

local function split(text)
  local tokens = {}
  for word in text:gmatch("[^ ]+") do
    tokens[#tokens+1] = word
  end
  return tokens
end

local Reader = {}

local punct = {
  [','] = true,
  ['('] = true,
  [')'] = true,
  ['.'] = true,
  [';'] = true,
  ['!'] = true,
  ['?'] = true,
}

local function nextIsPunctuation(l, i)
  for j=i+1, #l, 1 do
    if type(l[j]) == "string" then
      return punct[l[j]:sub(1,1) or ""]
    end
  end
end

local function isPunctuation(l, i)
  if type(l[i]) == "string" then
    return punct[l[i]]
  end
end

-- TODO: perhaps make this a little smarter
local function ensureWidth(line, width)
  local lengths = {}
  local total = 0
  for i=1, #line, 1 do
    if type(line[i]) == "string" then
      lengths[i] = #line[i]
      total = total + #line[i]
    else
      lengths[i] = 0
    end
  end

  while lengths[#lengths] == 0 do lengths[#lengths] = nil end

  while total < width do
    local changed = false
    for i=1, #lengths, 1 do
      if total < width and lengths[i] > 0 and i < #lengths and (not
          nextIsPunctuation(line, i)) then
        line[i] = line[i] .. " "
        total = total + 1
        changed = true
      end
    end
    if not changed then break end
  end
end

local function getlen(cl)
  local len = 0

  for i=1, #cl, 1 do
    if type(cl[i]) == "string" then
      len = len + #cl[i] + 1
    end
  end

  return len
end

function Reader:init()
  local lines = {{}}

  local iter = function()
    return self.file:read("l")
  end

  local indent = 0

  for line in iter do
    local cline = lines[#lines]
    if line:sub(1,1) == "." then
      local directive, arg = line:match("^%.([^ ]+) +([^ ]+)$")
      if not directive then
        error("bad formatting: " .. line, 0)
      end

      if directive == "color" then
        if not colors[arg] then
          error("bad color: " .. arg, 0)
        end
        cline[#cline+1] = colors[arg]

      elseif directive == "break" then
        arg = tonumber(arg)

        if not arg then
          error("not a number: " .. arg, 0)
        end

        ensureWidth(cline, math.min(self.width-indent-1, getlen(cline)-1))
        cline[#cline+1] = "\n"
        for i=1, arg, 1 do
          lines[#lines+1] = {i < arg and "\n" or ""}
        end

      elseif directive == "head" then
        cline[#cline+1] = "\n"
        if #lines > 0 then
          lines[#lines+1] = {"\n"}
        end

        local text = iter()
        lines[#lines+1] = {colors.yellow, text, "\n"}
        lines[#lines+1] = {("="):rep(#text), colors.white,"\n"}

        lines[#lines+1] = {"\n"}
        lines[#lines+1] = {(" "):rep(indent)}

      elseif directive == "ident" then
        error(".ident is broken", 0)
        indent = tonumber(arg)
        if not indent then
          error("not a number: " .. arg, 0)
        end

      else
        error("bad directive: " .. directive, 0)
      end

    else
      local words = split(line)
      for i=1, #words, 1 do
        local len = getlen(cline)

        if len + #words[i] > self.width - indent - 1 then
          ensureWidth(cline, self.width - indent - 1)
          cline[#cline+1] = "\n"
          cline[1] = (" "):rep(indent) .. cline[1]
          lines[#lines+1] = {}
          cline = lines[#lines]
        end

        cline[#cline+1] = words[i]
      end
    end
  end

  self.file:close()

  local elements = {}

  for i=1, #lines, 1 do
    local line = lines[i]
    for e=1, #line, 1 do
      elements[#elements+1] = line[e]
    end
  end

  self.elements = elements
  self.eid = 0

  return self
end

-- return the entire text as something you can unpack into
-- textutils.coloredPagedPrint
function Reader:read()
  local ret = {}

  for element in function() return self:readElement() end do
    ret[#ret+1] = element
  end

  return ret
end

function Reader:readElement()
  self.eid = self.eid + 1
  return self.elements[self.eid]
end

function Reader:wrap(width)
  expect(1, width, "number")
  self.width = width
end

local Writer = {}

function lib.reader(file)
  expect(1, file, "string")

  local handle, err = io.open(file, "r")
  if not handle then
    return nil, file .. ": " .. err
  end

  return setmetatable({file=handle,width=require("term").getSize()},
    {__index=Reader})
end

function lib.writer(file)
  expect(1, file, "string")

  local handle, err = io.open(file, "w")
  if not handle then
    return nil, file .. ": " .. err
  end

  return setmetatable({file=handle}, {__index=Writer})
end

return lib
