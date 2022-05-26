-- Recrafted coroutine manager

local rc = require("rc")

rc.thread = {}

local isRunning = false
local threads = {}

local id = 0
local current = 0

function rc.thread.add(func, name)
  rc.expect(1, func, "function")
  rc.expect(2, name, "string", "nil")

  local cur = threads[current] or {
    dir = "/",
    vars = {}
  }

  threads[id+1] = {coro = coroutine.create(func),
    name = name or tostring(func),
    dir = cur.dir, vars = setmetatable({}, {__index = cur.vars})}
  id = id + 1

  return id
end

function rc.vars()
  return threads[current].vars
end

function rc.dir()
  return threads[current].dir
end

function rc.setDir(dir)
  rc.expect(1, dir, "string")

  if not rc.fs.exists(dir) then
    return nil, "that directory does not exist"

  elseif not rc.fs.isDir(dir) then
    return nil, "not a directory"
  end

  threads[current].dir = dir
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
    running[#running+1] = {id = i, name = thread.name}
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
      local result = table.pack(coroutine.resume(thread.coro,
        table.unpack(event, 1, event.n)))

      if not result[1] then
        rc.printError(string.format("thread %d (%s): %s", _id, thread.name,
          result[2]))
        threads[_id] = nil
      end
    end
  end

  rc.printError("all threads have exited")
  os.sleep(2)

  os.shutdown()
end

return rc.thread
