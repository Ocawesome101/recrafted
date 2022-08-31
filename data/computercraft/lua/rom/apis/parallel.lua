-- 'parallel' implementation
-- uses Recrafted's native threading

local parallel = {}

local thread = require("rc.thread")
local expect = require("cc.expect").expect

local function rand_id()
  local id = "parallel-"
  for _=1, 8, 1 do
    id = id .. string.char(math.random(33, 126))
  end
  return id
end

local function waitForN(num, ...)
  local funcs = table.pack(...)

  local threads = {}
  for i=1, #funcs, 1 do
    expect(i, funcs[i], "function")
  end

  for i=1, #funcs, 1 do
    threads[i] = thread.spawn(funcs[i], rand_id())
  end

  local dead = 0
  repeat
    coroutine.yield()
    for i=#threads, 1, -1 do
      if not thread.exists(threads[i]) then
        table.remove(threads, i)
        dead = dead + 1
      end
    end
  until dead >= num

  -- clean up excess
  for i=1, #threads, 1 do
    thread.remove(threads[i])
  end
end

function parallel.waitForAny(...)
  return waitForN(1, ...)
end

function parallel.waitForAll(...)
  return waitForN(select("#", ...), ...)
end

return parallel
