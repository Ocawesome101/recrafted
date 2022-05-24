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

  local absolute = fs.combine(location, path)
  local dir = fs.getDir(path)

  if not fs.exists(dir) or not fs.isDir(dir) then
    return nil
  end

  local files = fs.list(dir)
end
