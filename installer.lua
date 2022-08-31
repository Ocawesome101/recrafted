-- Recrafted installer

print("Downloading required libraries...")

local function dl(f)
  local hand, err = http.get(f, nil, true)
  if not hand then
    error(err, 0)
  end

  local data = hand.readAll()
  hand.close()

  return data
end

-- set up package.loaded for Recrafted libs
package.loaded.rc = {
  expect = require("cc.expect").expect,
  write = write, sleep = sleep
}

package.loaded.term = term
package.loaded.colors = colors
_G.require = require

function term.at(x, y)
  term.setCursorPos(x, y)
  return term
end

local function ghload(f, c)
  return assert(load(dl("https://raw.githubusercontent.com/"..f),
    "="..(c or f), "t", _G))()
end

local json = ghload("rxi/json.lua/master/json.lua", "ghload(json)")
package.loaded["rc.json"] = json

local function rcload(f)
  return ghload(
    "ocawesome101/recrafted/primary/data/computercraft/lua/rom/"..f, f)
end

-- get recrafted's textutils with its extra utilities
local tu = rcload("apis/textutils.lua")

local function progress(y, a, b)
  local progress = a/b

  local w = term.getSize()
  local bar = (" "):rep(math.ceil((w-2) * progress))
  term.at(1, y)
  tu.coloredPrint(colors.yellow, "[", {fg=colors.white, bg=colors.white}, bar,
    {fg=colors.white, bg=colors.black}, (" "):rep((w-2)-#bar),
    colors.yellow, "]")
end

term.at(1,1).clear()
tu.coloredPrint(colors.yellow,
  "Recrafted Installer 1.0\n=======================")

local ROM_DIR
tu.coloredPrint("Enter installation directory ", colors.yellow, "[",
  colors.lightBlue, "/rc", colors.yellow, "]")
tu.coloredWrite(colors.yellow, "> ")

ROM_DIR = read()
if #ROM_DIR == 0 then ROM_DIR = "/rc" end

ROM_DIR = "/"..shell.resolve(ROM_DIR)

settings.set("recrafted.rom_dir", ROM_DIR)
settings.save()

tu.coloredPrint(colors.white, "Installing Recrafted to ", colors.lightBlue,
  ROM_DIR, colors.white)

local function bullet(t)
  tu.coloredWrite(colors.red, "- ", colors.white, t)
end

local function ok()
  tu.coloredPrint(colors.green, "OK", colors.white)
end

bullet("Getting repository tree...")

local repodata = dl("https://api.github.com/repos/ocawesome101/recrafted/git/trees/primary?recursive=1")

repodata = json.decode(repodata)

ok()

bullet("Filtering files...")
local look = "data/computercraft/lua/"
local to_dl = {}
for _, v in pairs(repodata.tree) do
  if v.path and v.path:sub(1,#look) == look then
    v.path = v.path:sub(#look+1)
    v.real_path = v.path:gsub("^/?rom", ROM_DIR)
    to_dl[#to_dl+1] = v
  end
end
ok()

bullet("Creating directories...")
for i=#to_dl, 1, -1 do
  local v = to_dl[i]
  if v.type == "tree" then
    fs.makeDir(fs.combine(v.real_path))
    table.remove(to_dl, i)
  end
end
ok()

bullet("Downloading files...")
local okx, oky = term.getCursorPos()
io.write("\n")
local _, pby = term.getCursorPos()

local parallels = {}
local done = 0

for i=1, #to_dl, 1 do
  local v = to_dl[i]
  if v.type == "blob" then
    parallels[#parallels+1] = function()
      local data = dl("https://raw.githubusercontent.com/ocawesome101/recrafted/primary/data/computercraft/lua/"..v.path)
      assert(io.open(v.real_path, "w")):write(data):close()
      done = done + 1
      progress(pby, done, #to_dl)
    end
  end
end

parallel.waitForAll(table.unpack(parallels))

term.at(1, pby).write((" "):rep((term.getSize())))
term.at(okx, oky)
ok()

assert(io.open(
 fs.exists("/startup.lua") and "/unbios-rc.lua" or "/startup.lua", "w"))
  :write(dl(
   "https://raw.githubusercontent.com/ocawesome101/recrafted/primary/unbios.lua"
  )):close()

tu.coloredPrint(colors.yellow, "Your computer will restart in 5 seconds.")
local _, y = term.getCursorPos()

for i=1, 5, 1 do
  progress(y, i, 5)
  os.sleep(1)
end

os.reboot()
