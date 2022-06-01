-- rc.disk

local p = require("peripheral")

local disk = {}

local function wrap(method)
  return function(name, ...)
    if not p.isPresent(name) then
      return nil
    end

    return p.call(name, method, ...)
  end
end

local methods = {
  isPresent = "isDiskPresent",
  getLabel = "getDiskLabel",
  setLabel = "setDiskLabel",
  hasData = false,
  getMountPath = false,
  hasAudio = false,
  getAudioTitle = false,
  playAudio = false,
  stopAudio = false,
  eject = "ejectDisk",
  getID = "getDiskID"
}

for k, v in pairs(methods) do
  disk[k] = wrap(v or k)
end

return disk
