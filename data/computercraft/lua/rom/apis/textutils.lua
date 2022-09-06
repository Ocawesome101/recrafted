-- rc.textutils

local rc = require("rc")
local term = require("term")
local json = require("rc.json")
local colors = require("colors")
local expect = require("cc.expect").expect
local strings = require("cc.strings")

local tu = {}

function tu.slowWrite(text, rate)
  expect(1, text, "string")
  expect(2, rate, "number", "nil")

  local delay = 1/(rate or 20)
  for c in text:gmatch(".") do
    rc.write(c)
    rc.sleep(delay)
  end
end

function tu.slowPrint(text, rate)
  expect(1, text, "string")
  expect(2, rate, "number", "nil")
  tu.slowWrite(text.."\n", rate)
end

function tu.formatTime(time, _24h)
  expect(1, time, "number")
  expect(2, _24h, "boolean", "nil")

  local fmt = _24h and "!%H:%M" or "!%I:%M %p"

  return (os.date(fmt, time * 3600):gsub("^ ", ""))
end

local function pagedWrite(text, begin)
  local w, h = term.getSize()
  local x, y = term.getCursorPos()

  local realTotal = 0
  local lines = begin or 0

  local elements = strings.splitElements(text, w)

  strings.wrappedWriteElements(elements, w, false, {
    newline = function()
      rc.write("\n")
      realTotal = realTotal + 1
      lines = lines + 1
      x, y = term.getCursorPos()

      if lines >= h - 2 then
        local old = term.getTextColor()
        term.setTextColor(colors.white)
        rc.write("Press any key to continue")
        term.setTextColor(old)
        rc.pullEvent("char")
        local _, _y = term.getCursorPos()
        term.at(1, _y).clearLine()
        lines = 0
      end
    end,

    append = function(newText)
      term.at(x, y).write(newText)
      x = x + #newText
    end,

    getX = function() return x end
  })

  return realTotal, lines
end

function tu.pagedPrint(text)
  expect(1, text, "string")
  return pagedWrite(text .. "\n")
end

local function coloredWrite(paged, ...)
  local args = table.pack(...)
  local lines = 0
  local pageLines = 0

  local write = paged and pagedWrite or rc.write
  local old_fg, old_bg = term.getTextColor(), term.getBackgroundColor()
  local _, h = term.getSize()

  for i=1, args.n, 1 do
    if type(args[i]) == "number" then
      term.setTextColor(args[i])
    elseif type(args[i]) == "table" then
      if args[i].fg or args[i][1] then
        term.setTextColor(args[i].fg or args[i][1])
      end

      if args[i].bg or args[i][2] then
        term.setBackgroundColor(args[i].bg or args[i][2])
      end
    else
      local _lines, _tot = write(args[i], pageLines)
      lines = lines + _lines
      pageLines = _tot or 0
      while pageLines > h do pageLines = pageLines - h end
    end
  end

  term.setTextColor(old_fg)
  term.setBackgroundColor(old_bg)

  return lines
end

local function tabulate(paged, ...)
  local args = table.pack(...)

  local w = term.getSize()
  local max_len = 0

  local linear = {}

  for i=1, args.n, 1 do
    local argi = args[i]
    expect(i, argi, "table", "number")

    if type(argi) == "table" then
      for n=1, #argi, 1 do
        if type(argi[n]) == "table" then
          local total_len = 2
          local argin = argi[n]

          for j=1, #argin, 1 do
            expect(j, argin[j], "string", "number")
            if type(argin[j]) == "string" then
              total_len = total_len + #argin[j]
            end
          end

          argin.total_len = total_len
          max_len = math.max(max_len, total_len + 2)

          linear[#linear+1] = argi[n]

        else
          linear[#linear+1] = expect(n, argi[n], "string")
          max_len = math.max(max_len, #argi[n] + 2)
        end
      end

    else
      linear[#linear+1] = args[i]
    end
  end

  local written = 0

  local prt = paged and function(_args)
    if type(_args) == "string" then _args = {_args} end
    return coloredWrite(true, table.unpack(_args))
  end or function(_args)
    if type(_args) == "string" then _args = {_args} end
    return coloredWrite(false, table.unpack(_args))
  end

  for i=1, #linear, 1 do
    local lini = linear[i]

    if type(lini) == "number" then
      if written > 0 then
        prt("\n")
        written = 0
      end

      term.setTextColor(lini)

    else
      local len = type(lini) == "table" and lini.total_len or #lini
      if written + max_len > w then
        if written + len > w then
          prt("\n")
          prt(lini)
          rc.write((" "):rep(max_len - len))
          written = max_len

        else
          prt(lini)
          prt("\n")
          written = 0
        end

      else
        prt(lini)
        rc.write((" "):rep(max_len - len))
        written = written + max_len
      end
    end
  end

  if written > 0 then
    prt("\n")
  end
end

function tu.tabulate(...)
  tabulate(false, ...)
end

function tu.pagedTabulate(...)
  tabulate(true, ...)
end

local function mk_immut(str, field)
  return setmetatable({}, {
    __newindex = function()
      error(string.format("attempt to modify textutils.%s", field), 2)
    end,
    __tostring = function()
      return str
    end})
end

tu.empty_json_array = mk_immut("[]", "empty_json_array")
tu.json_null = mk_immut("null", "json_null")

local function serialize(t, _seen)
  local ret = ""

  if type(t) == "table" then
    local seen = setmetatable({}, {__index = _seen})

    ret = "{"
    for k, v in pairs(t) do
      if seen[k] then
        k = "<recursion>"
      end
      if seen[v] then
        v = "<recursion>"
      end
      if type(k) == "table" then
        seen[k] = true
      end
      if type(v) == "table" then
        seen[v] = true
      end
      ret = ret .. string.format("[%s] = %s,", serialize(k, seen),
        serialize(v, seen))
    end
    ret = ret .. "}"
  elseif type(t) == "function" or type(t) == "thread" or
      type(t) == "userdata" then
    error("cannot serialize type " .. type(t), 2)
  else
    return string.format("%q", t)
  end

  return ret
end

function tu.serialize(t, opts)
  expect(1, t, "table")
  expect(2, opts, "table", "nil")

  return serialize(t, {})
end

function tu.unserialize(s)
  expect(1, s, "string")
  local call = load("return " .. s, "=<unserialize>", "t", {})
  if call then return call() end
end

tu.serialise = tu.serialize
tu.unserialise = tu.unserialize

function tu.serializeJSON(t, nbt)
  expect(1, t, "table")
  if nbt then
    error("NBT mode is not yet supported")
  end
  return json.encode(t)
end

function tu.unserializeJSON(s)--s, options)
  expect(1, s, "string")
  return json.decode(s)
end

tu.serialiseJSON = tu.serializeJSON
tu.unserialiseJSON = tu.unserializeJSON

function tu.urlEncode(str)
  expect(1, str, "string")

  -- TODO: possibly UTF-8 support?
  str = str:gsub("[^%w %-%_%.]", function(c)
    return string.format("%%%02x", c:byte())
  end):gsub(" ", "+"):gsub("\n", "\r\n")

  return str
end

local function split(text)
  local dots = {""}

  for c in text:gmatch(".") do
    if c == "." or c == ":" then
      --dots[#dots+1] = c
      dots[#dots+1] = ""
    else
      dots[#dots] = dots[#dots] .. c
    end
  end

  return dots
end

local function getSuffix(thing, default)
  if type(thing) == "table" then
    return "."
  elseif type(thing) == "function" then
    return "("
  end
  return default
end

function tu.complete(text, env)
  expect(1, text, "string")
  env = expect(2, env, "table", "nil") or _G

  local last_exp = text:match("[^%(%)%%%+%-%*/%[%]%{%}; =]*$")

  local results = {}

  if last_exp and #last_exp > 0 then
    local search = {env}
    local mt = getmetatable(env)
    if mt and type(mt.__index) == "table" then
      search[#search+1] = mt.__index
    end

    for s=1, #search, 1 do
      local dots = split(last_exp)
      local current = search[s]

      local final = 0
      for i=1, #dots, 1 do
        if current[dots[i]] then
          current = current[dots[i]]
          final = i
        else
          break
        end
      end

      for _=1, final, 1 do table.remove(dots, 1) end

      if #dots == 0 then
        results[#results+1] = getSuffix(current)
      end

      if #dots ~= 1 or type(current) ~= "table" then return results end

      local find = dots[1]
      for key, val in pairs(current) do
        key = key .. getSuffix(val, "")

        if key:sub(1, #find) == find then
          results[#results+1] = key:sub(#find + 1)
        end
      end
    end
  end

  return results
end

function tu.coloredWrite(...)
  return coloredWrite(false, ...)
end

function tu.coloredPrint(...)
  return coloredWrite(false, ...) + rc.write("\n")
end

function tu.coloredPagedPrint(...)
  return coloredWrite(true, ...) + rc.write("\n")
end

return tu
