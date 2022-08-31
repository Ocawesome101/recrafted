-- rc.keys

local expect = require("cc.expect").expect

-- automatic keymap detection :)
-- this uses a fair bit of magic
local kmap = "lwjgl3"
local mcver = tonumber(_HOST:match("%b()"):sub(2,-2):match("1%.(%d+)")) or 0
if _HOST:match("CCEmuX") then
  -- use the 1.16.5 keymap
  kmap = "lwjgl3"
elseif mcver <= 12 or _HOST:match("CraftOS%-PC") then
  -- use the 1.12.2 keymap
  kmap = "lwjgl2"
end

local base = dofile("/rc/keymaps/"..kmap..".lua")
local lib = {}

-- reverse-index it!
for k, v in pairs(base) do lib[k] = v; lib[v] = k end
lib["return"] = lib.enter

function lib.getName(code)
  expect(1, code, "number")
  return lib[code]
end

return lib
