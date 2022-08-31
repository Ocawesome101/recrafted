-- HTTP library adapted from .OS --

-- native http.request: function(
--  url:string[, post:string[, headers:table[, binarymode:boolean]]])
--    post is the data to POST.  otherwise a GET is sent.
--  OR: function(parameters:table)
--    where parameters = {
--      url = string,     -- the URL
--      body = string,    -- the data to POST/PATCH/PUT
--      headers = table,  -- request headers
--      binary = boolean, -- self explanatory
--      method = string}  -- the HTTP method to use - one of:
--                            - GET
--                            - POST
--                            - HEAD
--                            - OPTIONS
--                            - PUT
--                            - DELETE
--                            - PATCH
--                            - TRACE
--
-- native http.checkURL: function(url:string)
--    url is a URL to try to reach.  queues a http_check event with the result.
-- native http.websocket(url:string[, headers:table])
--    url is the url to which to open a websocket.  queues a websocket_success
--    event on success, and websocket_failure on failure.
-- native http.addListener(port:number) (CraftOS-PC only)
--    add a listener on the specified port.  when that port receives data,
--    the listener queues a http_request(port:number, request, response).
--    !!the response is not send until response.close() is called!!
-- native http.removeListener(port:number) (CraftOS-PC only)
--    remove the listener from that port

local rc = ...

if not package.loaded.http then
  return
end

local old = package.loaded.http

local http = {}

package.loaded.http = http

local field = require("cc.expect").field
local expect = require("cc.expect").expect

local function listenForResponse(url)
  while true do
    local sig, a, b, c = rc.pullEvent()
    if sig == "http_success" and a == url then
      return b
    elseif sig == "http_failure" and a == url then
      return nil, b, c
    end
  end
end

function http.request(url, post, headers, binary, method, sync)
  if type(url) ~= "table" then
    url = {
      url = url,
      body = post,
      headers = headers,
      binary = binary,
      method = method or (post and "POST") or "GET",
      sync = not not sync
    }
  end

  field(url, "url", "string")
  field(url, "body", "string", "nil")
  field(url, "headers", "table", "nil")
  field(url, "binary", "boolean", "nil")
  field(url, "method", "string")
  field(url, "sync", "boolean", "nil")

  local ok, err = old.request(url)
  if not ok then
    return nil, err
  end

  if sync then return listenForResponse(url.url) end
end

function http.get(url, headers, binary)
  if type(url) == "table" then
    url.sync = true
    return http.request(url)
  else
    return http.request(url, nil, headers, binary, "GET", true)
  end
end

function http.post(url, body, headers, binary)
  if type(url) == "table" then
    url.sync = true
    url.method = "POST"
    return http.request(url)
  else
    return http.request(url, body, headers, binary, "POST", true)
  end
end

http.checkURLAsync = old.checkURL

function http.checkURL(url)
  expect(1, url, "string")

  local ok, err = old.checkURL(url)
  if not ok then
    return nil, err
  end

  local sig, _url, a, b
  repeat
    sig, _url, a, b = coroutine.yield()
  until sig == "http_check" and url == _url

  return a, b
end

http.websocketAsync = old.websocket

function http.websocket(url, headers)
  expect(1, url, "string")
  expect(2, headers, "string")

  local ok, err = old.websocket(url, headers)
  if not ok then
    return nil, err
  end

  while true do
    local sig, a, b, c = coroutine.yield()
    if sig == "websocket_success" and a == url then
      return b, c
    elseif sig == "websocket_failure" and a == url then
      return nil, b
    end
  end
end

if old.addListener then
  function http.listen(port, callback)
    expect(1, port, "number")
    expect(2, callback, "function")
    old.addListener(port)

    while true do
      local sig, a, b, c = coroutine.yield()
      if sig == "stop_listener" and a == port then
        old.removeListener(port)
        break
      elseif sig == "http_request" and  a == port then
        if not callback(b, c) then
          old.removeListener(port)
          break
        end
      end
    end
  end
else
  function http.listen()
    error("This functionality requires CraftOS-PC", 0)
  end
end
