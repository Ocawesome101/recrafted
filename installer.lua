-- Recrafted installer

local function dl(f)
  local hand, err = http.get(url..f, nil, true)
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
  write = write, sleep = sleep, term = term,
}

package.loaded.term = term
package.loaded.colors = colors

function term.at(x, y)
  term.setCursorPos(x, y)
  return term
end

local function ghload(f)
  return assert(load(dl("https://raw.githubusercontent.com/"..f),
    "="..f, "t", _G))()
end

local json = ghload("rxi/json.lua/master/json.lua")
package.loaded.json = json

local function rcload(f)
  return ghload("ocawesome101/recrafted/primary/data/computercraft/lua/rom/"..f)
end

-- get recrafted's textutils with its extra utilities
local tu = rcload("apis/textutils.lua")

local function progress(y, a, b)
  local progress = a/b

  local w = term.getSize()
  local bar = (" "):rep(math.ceil((w-2) * progress))
  term.at(1, y)
  tu.coloredPrint(colors.yellow, "[", {bg=colors.white}, bar,
    {bg=colors.black}, (" "):rep((w-2)-#bar), colors.yellow, "]")
end

term.at(1,1).clear()
tu.coloredPrint(colors.yellow, "Recrafted Installer 1.0")



local repodata = dl("https://api.github.com/repos/ocawesome101/recrafted/git/trees/primary?recursive=1")

repodata = json.decode(repodata)


