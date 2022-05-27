-- Recrafted coroutine manager

local rc = require("rc")

local threadapi = {}

local isRunning = false
local threads = {}

local id = 0
local current = 0

function threadapi.add(func, name)
  rc.expect(1, func, "function")
  rc.expect(2, name, "string", "nil")

  local cur = threads[current] or {
    dir = "/",
    vars = {},
    term = (rc.term.current or rc.term.native)()
  }

  threads[id+1] = {coro = coroutine.create(func),
    name = name or tostring(func), term = cur.term,
    dir = cur.dir, vars = setmetatable({}, {__index = cur.vars})}
  id = id + 1

  return id
end

function threadapi.vars()
  return threads[current].vars
end

function threadapi.dir()
  return threads[current].dir
end

function threadapi.setDir(dir)
  rc.expect(1, dir, "string")

  if not rc.fs.exists(dir) then
    return nil, "that directory does not exist"

  elseif not rc.fs.isDir(dir) then
    return nil, "not a directory"
  end

  threads[current].dir = dir
end

function threadapi.getTerm()
  if not threads[current] then
    return rc.term.native()
  end
  return threads[current].term
end

function threadapi.setTerm(t)
  rc.expect(1, t, "table", "nil")
  local cur = threads[current]
  if not cur then return rc.term.native() end
  local old = cur.term
  cur.term = t or cur.term
  return old
end

function threadapi.remove(tid)
  rc.expect(1, tid, "number", "nil")
  tid = tid or current
  if not threads[tid] then return false end
  threads[tid] = nil
  rc.sleep(0)
  return true
end

function threadapi.id()
  return current
end

function threadapi.info()
  local running = {}
  for i, thread in pairs(threads) do
    running[#running+1] = {id = i, name = thread.name}
  end
  table.sort(running, function(a,b) return a.id < b.id end)
  return running
end

function threadapi.exists(_id)
  rc.expect(1, id, "number")
  return not not threads[_id]
end

local yield = coroutine.yield
function threadapi.start()
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

      elseif coroutine.status(thread.coro) == "dead" then
        threads[_id] = nil

      end
    end
  end

  rc.printError("all threads have exited")
  os.sleep(2)

  os.shutdown()
end

return threadapi
