-- update: download a new copy of Recrafted

local rc = require("rc")
local term = require("term")
local colors = require("colors")
local textutils = require("textutils")

if not package.loaded.http then
  io.stderr:write("The HTTP API is disabled and the updater cannot continue.  Please enable the HTTP API in the ComputerCraft configuration and try again.\n")
  return
end

term.at(1,1).clear()

textutils.coloredPrint(colors.yellow,
  "Recrafted Updater (Stage 1)\n===========================")

print("Checking for update...")

local http = require("http")
local base = "https://raw.githubusercontent.com/ocawesome101/recrafted/primary/"

local Bhandle, Berr = http.get(base .. "data/computercraft/lua/bios.lua")
if not Bhandle then
  error(Berr, 0)
end

local first = Bhandle.readLine()
Bhandle.close()

local oldVersion = rc.version():gsub("Recrafted ", "")
local newVersion = first:match("Recrafted v?(%d+.%d+.%d+)")

if newVersion and (oldVersion ~= newVersion) or (...) == "-f" then
  textutils.coloredPrint(colors.green, "Found", colors.white, ": ",
    colors.red, oldVersion, colors.yellow, " -> ", colors.lime,
    newVersion or oldVersion)

  io.write("Apply update? [y/N]: ")
  if io.read() ~= "y" then
    textutils.coloredPrint(colors.red, "Not applying update.")
    return
  end

  textutils.coloredPrint(colors.green, "Applying update.")
  local handle, err = http.get(base.."updater.lua", nil, true)
  if not handle then
    error("Failed downloading stage 2: " .. err, 0)
  end

  local data = handle.readAll()
  handle.close()

  local out = io.open("/.start_rc.lua", "w")
  out:write(data)
  out:close()

  textutils.coloredWrite(colors.yellow, "Restarting...")
  rc.sleep(3)
  rc.reboot()
else
  textutils.coloredPrint(colors.red, "None found")
end
