-- devbin (like pastebin)

if not package.loaded.http then
  error("HTTP is not enabled in the ComputerCraft configuration", 0)
end

local http = require("http")
local json = require("rc.json")
local shell = require("shell")

local args = {...}

if #args < (args[1] == "get" and 3 or 2) then
  io.stderr:write([[
Usage:
devbin put <filename>
devbin get <code> <filename>
devbin run <code> [argument ...]
]])
  return
end

local paste = "https://devbin.dev/api/v3/paste"
local key = "aNVXl8vxYGWcZGvMnuJTzLXH53mGWOuQtBXU025g8YDAsZDu"

local function get(code)
  local handle, err, rerr = http.get("https://devbin.dev/raw/"..code)
  if not handle then
    if rerr then rerr.close() end
    error(err, 0)
  end

  local data = handle.readAll()
  handle.close()

  return data
end

if args[1] == "put" then
  local handle, err = io.open(shell.resolve(args[2]), "r")
  if not handle then error(err, 0) end
  local data = handle:read("a")
  handle:close()

  if (not data) or #data == 0 then
    error("cannot 'put' empty file", 0)
  end

  local request = json.encode({
    title = args[2],
    syntaxName = "lua",
    exposure = 0,
    content = data,
    asGuest = true
  })

  local response, rerr, rerr2 = http.post(paste, request,
    {["Content-Type"]="application/json", Authorization = key}, true)
  if not response then
    local _rerr2 = rerr2.readAll()
    if rerr2 then rerr2.close() end
    print(_rerr2)
    error(rerr, 0)
    --("%q: %q"):format(rerr, (rerr2 and rerr2.readAll()) or ""), 0)
  end

  local rdata = response.readAll()

  local code, message = response.getResponseCode()
  response.close()
  if code ~= 201 then
    error(code .. " " .. (message or ""), 0)
  end

  local decoded = json.decode(rdata)

  print(decoded.code)

elseif args[1] == "get" then
  local data = get(args[2])
  local handle, err = io.open(shell.resolve(args[3]), "w")
  if not handle then error(err, 0) end
  handle:write(data)
  handle:close()

elseif args[1] == "run" then
  local data = get(args[2])
  assert(load(data, "=<devbin-run>", "t", _G))()
end
