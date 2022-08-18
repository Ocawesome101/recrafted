-- rc.textutils

local rc = require("rc")
local term = require("term")
local json = require("json")
local colors = require("colors")

local tu = {}

function tu.slowWrite(text, rate)
  rc.expect(1, text, "string")
  rc.expect(2, rate, "number", "nil")

  local delay = 1/(rate or 20)
  for c in text:gmatch(".") do
    rc.write(c)
    rc.sleep(delay)
  end
end

function tu.slowPrint(text, rate)
  rc.expect(1, text, "string")
  rc.expect(2, rate, "number", "nil")
  tu.slowWrite(text.."\n", rate)
end

function tu.formatTime(time, _24h)
  rc.expect(1, time, "number")
  rc.expect(2, _24h, "boolean", "nil")

  local fmt = _24h and "!%H:%M" or "!%l:%M %p"

  return (os.date(fmt, time * 3600):gsub("^ ", ""))
end

local function pagedWrite(text, begin)
  local _, h = rc.term.getSize()

  local realTotal = 0
  local total = begin or 0

  for c in text:gmatch(".") do
    local writ = rc.write(c)
    total = total + writ
    realTotal = realTotal + writ

    if total >= h - 2 then
      local old = term.getTextColor()
      term.setTextColor(colors.white)
      rc.write("Press any key to continue")
      term.setTextColor(old)
      os.pullEvent("char")
      local _, y = term.getCursorPos()
      term.at(1, y).clearLine()
      total = 0
    end
  end

  return realTotal, total
end

function tu.pagedPrint(text)
  rc.expect(1, text, "string")
  return pagedWrite(text .. "\n")
end

local function coloredWrite(paged, ...)
  local args = table.pack(...)
  local lines = 0
  local pageLines = 0

  local write = paged and pagedWrite or rc.write
  local old = term.getTextColor()
  local _, h = term.getSize()

  for i=1, args.n, 1 do
    if type(args[i]) == "number" then
      term.setTextColor(args[i])
    elseif type(args[i]) == "table" then
      term.setTextColor(args[i].fg or args[i][1])
      term.setBackgroundColor(args[i].bg or args[i][2])
    else
      local _lines, _tot = write(args[i], pageLines)
      lines = lines + _lines
      pageLines = _tot or 0
      while pageLines > h do pageLines = pageLines - h end
    end
  end

  term.setTextColor(old)

  return lines
end

local function tabulate(paged, ...)
  local args = table.pack(...)

  local w = rc.term.getSize()
  local max_len = 0

  local linear = {}

  for i=1, args.n, 1 do
    local argi = args[i]
    rc.expect(i, argi, "table", "number")

    if type(argi) == "table" then
      for n=1, #argi, 1 do
        if type(argi[n]) == "table" then
          local total_len = 2
          local argin = argi[n]

          for j=1, #argin, 1 do
            rc.expect(j, argin[j], "string", "number")
            if type(argin[j]) == "string" then
              total_len = total_len + #argin[j]
            end
          end

          argin.total_len = total_len
          max_len = math.max(max_len, total_len + 2)

          linear[#linear+1] = argi[n]

        else
          linear[#linear+1] = rc.expect(n, argi[n], "string")
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

      rc.term.setTextColor(lini)

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
  rc.expect(1, t, "table")
  rc.expect(2, opts, "table", "nil")

  return serialize(t, {})
end

function tu.unserialize(s)
  rc.expect(1, s, "string")
  local call = load("return " .. s, "=<unserialize>", "t", {})
  if call then return call() end
end

tu.serialise = tu.serialize
tu.unserialise = tu.unserialize

function tu.serializeJSON(t, nbt)
  rc.expect(1, t, "table")
  if nbt then
    error("NBT mode is not yet supported")
  end
  return json.encode(t)
end

function tu.unserializeJSON(s)--s, options)
  rc.expect(1, s, "string")
  return json.decode(s)
end

tu.serialiseJSON = tu.serializeJSON
tu.unserialiseJSON = tu.unserializeJSON

function tu.urlEncode(str)
  rc.expect(1, str, "string")

  -- TODO: possibly UTF-8 support?
  str = str:gsub("[^%w %-%_%.]", function(c)
    return string.format("%%%02x", c)
  end):gsub(" ", "+"):gsub("\n", "\r\n")

  return str
end

function tu.complete()
  error("not yet implemented")
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
