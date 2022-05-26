-- rc.textutils

local rc = ...

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

  local fmt = _24h and "%H:%M" or "%I:%M %p"

  return os.date(fmt, time)
end

function tu.pagedPrint(text, free_lines)
  rc.expect(1, text, "string")
  rc.expect(2, free_lines, "number", "nil")

  free_lines = free_lines or 0
  rc.term.scroll(free_lines + 1)
  local _, y = rc.term.getCursorPos()
  local _, h = rc.term.getSize()
  rc.term.setCursorPos(1, y - free_lines)

  local realTotal = 0
  local total = 0
  for c in (text .. "\n"):gmatch(".") do
    local writ = rc.write(c)
    total = total + writ
    realTotal = realTotal + writ
    if total >= h - 2 then
      rc.write("Press any key to continue")
      os.pullEvent("key")
      rc.write("\n")
      total = 0
    end
  end

  return realTotal
end

local function pad(t, w)
  return t .. string.rep(" ", w - #t)
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
        linear[#linear+1] = rc.expect(n, argi[n], "string")
        max_len = math.max(max_len, #argi[n])
      end

    else
      linear[#linear+1] = args[i]
    end
  end

  local line = ""

  local prt = paged and tu.pagedPrint or print

  for i=1, #linear, 1 do
    local lini = linear[i]

    if type(lini) == "number" then
      if #line > 0 then
        prt(line)
        line = ""
      end

      rc.term.setTextColor(lini)

    else
      if #line + max_len > w then
        if #line + #lini > w then
          prt(line)
          line = pad(lini, max_len)

        else
          line = line .. lini
          prt(line)
          line = ""
        end

      else
        line = line .. pad(lini, max_len)
      end
    end
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
    error("cannot serialize type " .. t, 2)
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
  return load("return " .. s, "=<unserialize>", "t", {})
end

tu.serialise = tu.serialize
tu.unserialise = tu.unserialize

function tu.serializeJSON()--t, nbt)
  error("not yet implemented")
end

function tu.unserializeJSON()--s, options)
  error("not yet implemented")
end

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

rc.textutils = tu
