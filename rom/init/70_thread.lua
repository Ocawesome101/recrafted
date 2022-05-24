-- Recrafted coroutine manager

local rc = ...

rc.thread = {}

local isRunning = false
local threads = {}

function rc.thread.add(func)
  rc.expect(1, func, "function")
end

function rc.thread.remove()
end

function rc.thread.info()
end

function rc.thread.start()
  if isRunning then
    error("an rc.thread instance is already running")
  end
  isRunning = true

  while true do
    for id, thread in pairs(threads) do
    end
  end

  rc.printError("all threads have died")

  rc.shutdown()
end
