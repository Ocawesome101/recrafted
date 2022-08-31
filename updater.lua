-- Recrafted updater: stage 2

local fs = rawget(_G, "fs")
local term = rawget(_G, "term")
local http = rawget(_G, "http")

_G._RC_ROM_DIR = _RC_ROM_DIR or "/rc"
if _RC_ROM_DIR == "/rom" then _RC_ROM_DIR = "/rc" end

-- fail-safe
local start_rc = [[

local fs = rawget(_G, "fs")
local term = rawget(_G, "term")

local w, h = term.getSize()
local function at(x,y)
  term.setCursorPos(x,y)
  return term
end

term.setBackgroundColor(0x1)
at(1,1).clearLine()
at(1,h).clearLine()

local title = "Recrafted Updater (Failure Notice)"
term.setTextColor(0x4000)
at(math.floor(w/2-#title/2), 1).write(title)

for i=2, h-1, 1 do
  term.setBackgroundColor(0x4000)
  at(1,i).clearLine()
end

term.setTextColor(0x1)
local message = {
  "A Recrafted update has failed or",
  "been interrupted.  Your files are",
  "intact.",
  "",
  "Press any key to revert to the ROM.",
  "",
  "",
}

for i=1, #message, 1 do
  at(3, i+2).write(message[i])
end

term.setCursorBlink(true)

repeat local x = coroutine.yield() until x == "char"

pcall(fs.delete, _RC_ROM_DIR)
pcall(fs.delete, "/.start_rc.lua")

os.reboot()
while true do coroutine.yield() end

]]

local function at(x,y)
  term.setCursorPos(x,y)
  return term
end

local handle = fs.open("/.start_rc.lua", "w")
handle.write(start_rc)
handle.close()

assert(pcall(function()
local w, h = term.getSize()

local function dl(f)
  local hand, err = http.request(f, nil, nil, true)
  local evt
  repeat
    evt = table.pack(coroutine.yield())
  until evt[1] == "http_success" or evt[1] == "http_failure"

  if evt[1] == "http_failure" then
    term.at(1, h).write(evt[3])

    local id = os.startTimer(5)
    repeat local _,i = coroutine.yield() until i == id

    os.reboot()
    while true do coroutine.yield() end

  else
    hand = evt[3]

    local data = hand.readAll()
    hand.close()

    return data
  end
end

local function ghload(f, c)
  return assert(loadstring(dl("https://raw.githubusercontent.com/"..f),
    "=ghload("..(c or f)..")"))()
end

local json = ghload("rxi/json.lua/master/json.lua", "json")

local function header()
  term.setTextColor(0x10)
  at(1, 1).clearLine()
  at(1, 1).write("Recrafted Updater (Stage 2)")
  at(1, 2).clearLine()
  at(1, 2).write("===========================")
  term.setTextColor(0x1)
end

local y = 1
local function write(text)
  if y > h-3 then
    term.scroll(1)
    header()
  else
    y = y + 1
  end
  at(1, y+2).write(text)
end

header()

write("Getting repository tree...")

local repodata = json.decode(dl("https://api.github.com/repos/ocawesome101/recrafted/git/trees/primary?recursive=1"))

write("Filtering files...")

local look = "data/computercraft/lua/"
local to_dl = {}
for _, v in pairs(repodata.tree) do
  if v.path and v.path:sub(1,#look) == look then
    v.path = v.path:sub(#look+1)
    v.real_path = v.path:gsub("^/?rom", _RC_ROM_DIR)
    to_dl[#to_dl+1] = v
  end
end

write("Creating directories...")

for i=#to_dl, 1, -1 do
  local v = to_dl[i]
  if v.type == "tree" then
    fs.makeDir(fs.combine(v.real_path))
    table.remove(to_dl, i)
  end
end

write("Downloading files...")

local function progress(a, b)
  at(1, 3).clearLine()
  term.setBackgroundColor(0x1)
  at(1, 3).write((" "):rep(math.ceil((w-2) * (a/b))))
  term.setBackgroundColor(0x8000)
end

for i=1, #to_dl do
  local v = to_dl[i]
  if v.type == "blob" and v.real_path ~= "unbios.lua" then
    local data = dl("https://raw.githubusercontent.com/ocawesome101/recrafted/primary/data/computercraft/lua/"..v.path)
    write(v.real_path)
    progress(i, #to_dl)
    if v.real_path == "bios.lua" then
      v.real_path = "/.start_rc.lua"
    end
    local handle = fs.open(v.real_path, "w")
    handle.write(data)
    handle.close()
  end
end

os.reboot()
while true do coroutine.yield() end

end))
