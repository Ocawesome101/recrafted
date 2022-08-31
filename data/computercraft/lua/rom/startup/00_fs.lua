-- override the fs library to use this resolution function where necessary
-- almost identical to the override used in .OS

local fs = rawget(_G, "fs")

-- split a file path into segments
function fs.split(path)
  local s = {}
  for S in path:gmatch("[^/\\]+") do
    if S == ".." then
      s[#s] = nil
    elseif S ~= "." then
      s[#s+1] = S
    end
  end
  return s
end

-- package isn't loaded yet, so unfortunately this is necessary
local function expect(...)
  return require and require("cc.expect").expect(...)
end

-- path resolution:
-- if the path begins with /rc, then redirect to wherever that actually
-- is; otherwise, resolve the path based on the current program's working
-- directory
-- this is to allow .OS to run from anywhere
local function resolve(path)
  local thread = package and package.loaded.thread

  local root = (thread and thread.getroot()) or "/"
  local pwd = (thread and thread.dir()) or "/"

  if path:sub(1,1) ~= "/" then
    path = fs.combine(pwd, path)
  end
  path = fs.combine(root, path)

  local segments = fs.split(path)
  if segments[1] == "rc" then
    return fs.combine(_RC_ROM_DIR, table.concat(segments, "/", 2, #segments))
  else
    return path
  end
end

-- override: fs.combine
local combine = fs.combine
function fs.combine(...)
  return "/" .. combine(...)
end

-- override: fs.getDir
local getDir = fs.getDir
function fs.getDir(p)
  return "/" .. getDir(p)
end

-- override: fs.exists
local exists = fs.exists
function fs.exists(path)
  expect(1, path, "string")
  return exists(resolve(path))
end

-- override: fs.list
local list = fs.list
function fs.list(path)
  expect(1, path, "string")
  path = resolve(path)
  local _, files = pcall(list, path)
  if not _ then return nil, files end
  if path == "/" then
    -- inject /rc into the root listing
    if not exists("/rc") then
      files[#files+1] = "rc"
    end
  end
  return files
end

-- override: fs.getSize
local getSize = fs.getSize
function fs.getSize(path)
  expect(1, path, "string")
  return getSize((resolve(path)))
end

-- override: fs.isDir
local isDir = fs.isDir
function fs.isDir(path)
  expect(1, path, "string")
  return isDir(resolve(path))
end

-- override: fs.makeDir
local makeDir = fs.makeDir
function fs.makeDir(path)
  expect(1, path, "string")
  return makeDir(resolve(path))
end

-- override: fs.move
local move = fs.move
function fs.move(a, b)
  expect(1, a, "string")
  expect(2, b, "string")
  return move(resolve(a), resolve(b))
end

-- override: fs.copy
local copy = fs.copy
function fs.copy(a, b)
  expect(1, a, "string")
  expect(2, b, "string")
  return copy(resolve(a), resolve(b))
end

-- override: fs.delete
local delete = fs.delete
function fs.delete(path)
  expect(1, path, "string")
  return delete(resolve(path))
end

-- override: fs.open
local open = fs.open
function fs.open(file, mode)
  expect(1, file, "string")
  expect(2, mode, "string")
  return open(resolve(file), mode or "r")
end

-- override: fs.find
local find = fs.find
function fs.find(path)
  expect(1, path, "string")
  return find(resolve(path))
end

-- override: fs.attributes
local attributes = fs.attributes
function fs.attributes(path)
  expect(1, path, "string")
  return attributes(resolve(path))
end

-- new: fs.complete
function fs.complete(path, location, include_files, include_dirs)
  expect(1, path, "string")
  expect(2, location, "string")
  expect(3, include_files, "boolean", "nil")
  expect(4, include_dirs, "boolean", "nil")

  if include_files == nil then include_files = true end
  if include_dirs == nil then include_dirs = true end

  if path:sub(1,1) == "/" and path:sub(-1) ~= "/" then
    location = fs.getDir(path)
  elseif path:sub(-1) == "/" then
    location = path
  else
    location = fs.combine(location, fs.getDir(path))
  end

  local completions = {}

  if not fs.exists(location) or not fs.isDir(location) then
    return completions
  end

  local name = fs.getName(path)
  if path:sub(-1) == "/" then name = "" end
  local files = fs.list(location)

  for i=1, #files, 1 do
    local file = files[i]
    local full = fs.combine(location, file)
    if file:sub(1, #name) == name then
      local dir = fs.isDir(full)
      if (dir and include_dirs) or include_files then
        completions[#completions+1] = file:sub(#name+1)
        if #completions[#completions] == 0 then
          completions[#completions] = nil
        end
      end
      if dir then
        completions[#completions+1] = file:sub(#name+1) .. "/"
      end
    end
  end

  return completions
end

function fs.isDriveRoot(path)
  expect(1, path, "string")
  if #path == 0 then path = "/" end
  return path == "/" or fs.getDrive(path) == fs.getDrive(fs.getDir(path))
end
