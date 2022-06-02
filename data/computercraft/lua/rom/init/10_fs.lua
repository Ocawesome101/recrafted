-- Recrafted fs API extensions

local rc = ...

local expect = require("cc.expect")

local fs = rc.fs

-- new: fs.complete
function fs.complete(path, location, include_files, include_dirs)
  expect(1, path, "string")
  expect(2, location, "string")
  expect(3, include_files, "boolean", "nil")
  expect(4, include_dirs, "boolean", "nil")

  if include_files == nil then include_files = true end
  if include_dirs == nil then include_dirs = true end

  if path:sub(1,1) == "/" then
    location = fs.getDir(path)
  end

  if not fs.exists(location) or not fs.isDir(location) then
    return nil
  end

  local name = fs.getName(path)
  local files = fs.list(location)

  local completions = {}

  for i=1, #files, 1 do
    local file = files[i]
    local full = fs.combine(location, file)
    if files[i]:sub(1, #name) == name then
      local dir = fs.isDir(full)
      if (dir and include_dirs) or include_files then
        completions[#completions+1] = file:sub(#name+1)
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
