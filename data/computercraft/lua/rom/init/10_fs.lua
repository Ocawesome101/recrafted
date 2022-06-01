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
    --local full = fs.combine(location, files[i])
    if files[i]:sub(1, #name) == name then
      completions[#completions+1] = files[i]:sub(#name+1)
    end
  end

  return completions
end

function fs.isDriveRoot(path)
  expect(1, path, "string")
  if #path == 0 then path = "/" end
  return path == "/" or fs.getDrive(path) == fs.getDrive(fs.getDir(path))
end
