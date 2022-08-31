-- wget

if not package.loaded.http then
  error("HTTP is not enabled in the ComputerCraft configuration", 0)
end

local http = require("http")

local args = {...}

if #args == 0 then
  io.stderr:write([[Usage:
wget <url> [filename]
wget run <url>
]])
  return
end

local function get(url)
  local handle, err = http.get(url, nil, true)
  if not handle then
    error(err, 0)
  end

  local data = handle.readAll()
  handle.close()

  return data
end

local data = get(args[1])

if args[1] == "run" then
  assert(load(data, "=<wget-run>", "t", _G))()
else
  local filename = args[2] or (args[1]:match("[^/]+$")) or
    error("could not determine file name", 0)
  local handle, err = io.open(filename, "w")
  if not handle then
    error(err, 0)
  end
  handle:write(data)
  handle:close()
end
