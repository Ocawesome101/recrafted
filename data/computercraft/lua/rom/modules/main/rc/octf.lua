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

local function getlen(cline, real)
  local len = 0

  for i=1, #cline, 1 do
    if type(cline[i]) == "string" then
      len = len + #cline[i] + ((real and 0) or 1)
    end
  end

  return len
end

local punct = "^[,%.;:] *$"
local function ensureWidth(line, width)
  local len = getlen(line, true)

  while len < width do
    if len < width then
      -- first, go through and add spaces after punctuation
      for i=1, #line, 1 do
        if type(line[i]) == "string" and line[i]:match(punct) and
              line[i]:sub(-1) ~= "\n" then
          line[i] = line[i] .. " "
          len = len + 1
          if len == width then break end
        end
      end
    end

    if len < width then
      for i=1, #line, 1 do
        if type(line[i]) == "string" and line[i]:sub(-1) ~= "\n" and not
            (type(line[i+1]) == "string" and line[i+1]:match(punct)) then
          line[i] = line[i] .. " "
          len = len + 1
          if len == width then break end
        end
      end
    end
  end
end

function Reader:init()
  local elements = {}

  local cline = {}

  local iter = function()
    return self.file:read("l")
  end

  local indent = 0

  local function addLine(setwidth)
    cline[#cline+1] = "\n"
    local str = 1
    for i=1, #cline, 1 do
      if type(cline[i]) == "string" then
        str = i
        break
      end
    end

    cline[str] = (" "):rep(indent) .. cline[str]

    if setwidth then
      ensureWidth(cline, self.width - indent)
    else
      for i=1, #cline, 1 do
        if type(cline[i]) == "string" and not (type(cline[i+1]) == "string"
            and cline[i+1]:match(punct)) and cline[i]:sub(-1) ~= "\n" then
          cline[i] = cline[i] .. " "
        end
      end
    end
    for i=1, #cline, 1 do
      elements[#elements+1] = cline[i]
    end
    cline = {}
  end

  for line in iter do
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
        for _=1, tonumber(arg), 1 do
          addLine(false)
        end
      end

    else
      local words = split(line)
      for i=1, #words, 1 do
        local len = getlen(cline)

        if len + #words[i] > self.width - indent then
          addLine(true)
        end

        cline[#cline+1] = words[i]
      end
    end
  end

  self.file:close()

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
