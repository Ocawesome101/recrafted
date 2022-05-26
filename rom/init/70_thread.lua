-- Recrafted coroutine manager

local rc = ...

rc.thread = {}

local isRunning = false
local threads = {}

local id = 0
local current = 0

function rc.thread.add(func)
  rc.expect(1, func, "function")
  threads[id+1] = coroutine.create(func)
  id = id + 1
  return id
end

function rc.thread.remove(tid)
  rc.expect(1, tid, "number", "nil")
  tid = tid or current
  if not threads[tid] then return false end
  threads[tid] = nil
  return true
end

function rc.thread.id()
  return current
end

function rc.thread.info()
  local running = {}
  for i, thread in pairs(threads) do
    running[#running+1] = {id = i, ident = tostring(thread)
      :match("thread: (.+)")}
  end
  return running
end

local yield = coroutine.yield
function rc.thread.start()
  if isRunning then
    error("an rc.thread instance is already running")
  end
  isRunning = true

  while next(threads) do
    local event = table.pack(yield())
    for _id, thread in pairs(threads) do
      current = _id
      local result = table.pack(coroutine.resume(thread,
        table.unpack(event, 1, event.n)))
      if not result[1] then
        rc.printError(string.format("thread %d: %s", _id, result[2]))
        threads[_id] = nil
      end
    end
  end

  rc.printError("all threads have exited")
  os.sleep(2)

  os.shutdown()
end
