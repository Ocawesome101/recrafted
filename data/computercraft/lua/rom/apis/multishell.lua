-- multishell API

local thread = require("rc.thread")

local ms = {}

ms.getFocus = thread.getFocusedTab
ms.setFocus = thread.setFocusedTab
ms.getCurrent = thread.getCurrentTab

ms.setTitle = function() end
ms.getTitle = function() return "???" end

ms.getCount = function() return #thread.info() end

function ms.launch(...)
  local env = _G
  local args = table.pack(...)

  if type(args[1]) == "table" then
    env = table.remove(args, 1)
  end

  local function func()
    return assert(loadfile(args[1], "bt", env))(table.unpack(args, 2, args.n))
  end

  return (thread.launchTab(func, args[1]:sub(-8)))
end

return ms
