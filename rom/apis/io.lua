-- rc.io

local rc = require("rc")
local thread = require("thread")
local colors = require("colors")

local io = {}

local _file = {}
function _file:read(...)
  local args = table.pack(...)
  local ret = {}

  if args.n == 0 then
    args[1] = "l"
    args.n = 1
  end

  if not (self.handle.read and pcall(self.handle.read, 0)) then
    return nil, "bad file descriptor"
  end

  for i=1, args.n, 1 do
    local format = args[i]
    if format:sub(1,1) == "*" then
      format = format:sub(2)
    end

    if format == "a" then
      ret[#ret+1] = self.handle.readAll()

    elseif format == "l" or format == "L" then
      ret[#ret+1] = self.handle.readLine(format == "L")

    elseif type(format) == "number" then
      ret[#ret+1] = self.handle.read(format)

    else
      error("invalid format '"..format.."'", 2)
    end
  end

  return table.unpack(ret, 1, args.n)
end

function _file:lines(...)
  local formats = {...}
  if #formats == 0 then
    formats[1] = "l"
  end
  return function()
    return self:read(table.unpack(formats))
  end
end

function _file:write(...)
  local args = table.pack(...)

  if not (self.handle.write and pcall(self.handle.write, "")) then
    return nil, "bad file descriptor"
  end

  for i=1, args.n, 1 do
    self.handle.write(args[i])
  end

  return true
end

function _file:seek(whence, offset)
  rc.expect(1, whence, "string", "nil")
  rc.expect(2, offset, "number", "nil")
  if self.handle.seek then
    return self.handle.seek(whence, offset)
  else
    return nil, "bad file descriptor"
  end
end

function _file:flush()
  if self.handle.flush then self.handle.flush() end
end

function _file:close()
  self.closed = true
  pcall(self.handle.close)
end

local function iofile(handle)
  return setmetatable({handle = handle, closed = false}, {__index = _file})
end

local stdin_rbuf = ""
io.stdin = iofile {
  read = function(n)
    while #stdin_rbuf < n do
      stdin_rbuf = stdin_rbuf .. rc.term.read() .. "\n"
    end
    local ret = stdin_rbuf:sub(1, n)
    stdin_rbuf = stdin_rbuf:sub(#ret+1)
    return ret
  end,

  readLine = function(trail)
    local nl = stdin_rbuf:find("\n")

    if nl then
      local ret = stdin_rbuf:sub(1, nl+1)
      if not trail then ret = ret:sub(1, -2) end
      stdin_rbuf = stdin_rbuf:sub(#ret+1)
      return ret

    else
      return stdin_rbuf .. rc.term.read() .. (trail and "\n" or "")
    end
  end
}

io.stdout = iofile {
  write = rc.write
}

io.stderr = iofile {
  write = function(text)
    local old = rc.term.getTextColor()
    rc.term.setTextColor(colors.red)
    rc.write(text)
    rc.term.setTextColor(old)
  end
}

function io.open(file, mode)
  rc.expect(1, file, "string")
  rc.expect(2, mode, "string", "nil")

  mode = (mode or "r"):match("[rwa]") .. "b"

  local handle, err = rc.fs.open(file, mode)
  if not handle then
    return nil, err
  end

  return iofile(handle)
end

function io.input(file)
  rc.expect(1, file, "string", "table", "nil")
  local vars = thread.vars()
  if type(file) == "string" then file = assert(io.open(file, "r")) end
  if file then vars.input = file end
  return vars.input or io.stdin
end

function io.output(file)
  rc.expect(1, file, "string", "table", "nil")
  local vars = thread.vars()
  if type(file) == "string" then file = assert(io.open(file, "w")) end
  if file then vars.output = file end
  return vars.output or io.stdout
end

function io.read(...)
  return io.input():read(...)
end

function io.write(...)
  return io.output():write(...)
end

function io.flush(file)
  rc.expect(1, file, "table", "nil")
  return (file or io.output):flush()
end

function io.close(file)
  rc.expect(1, file, "table", "nil")
  return (file or io.output):close()
end

function io.lines(file, ...)
  rc.expect(1, file, "string", "nil")
  if file then file = assert(io.open(file, "r")) end
  local formats = table.pack(...)
  return function()
    return (file or io.stdin):lines(table.unpack(formats, 1, formats.n))
  end
end

function io.type(obj)
  if type(obj) == "table" then
    local is_file = true
    for k, v in pairs(_file) do
      if (not obj[k]) or v ~= obj[k] then
        is_file = false
      end
    end

    if is_file then
      return obj.closed and "closed file" or "file"
    end
  end
end

return io
