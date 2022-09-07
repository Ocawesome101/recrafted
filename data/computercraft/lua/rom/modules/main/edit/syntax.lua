-- A simple, fairly clever method of tokenizing code.
-- Each token is defined by a set of rules.  These rules are
-- accordingly defined in the relevant syntax definition file.
-- A rule takes the form of a triplet of functions:
--  - The first function takes a single character, and returns
--    whether that character is valid as part of the corresponding
--    token.
--  - The second function takes a single character and the current
--    token, and returns whether that character is valid as part
--    of the token.  This allows flexible implementations of highly
--    language-specific features such as strings.
--  - The third function takes only a token, and returns whether
--    that token is valid.
--
-- Multiple tokens may be evaluated in parallel and the longest is returned.

local lib = {}

local syntenv = {
  char = function(str)
    return {
      function(c)
        return c == str:sub(1,1)
      end,
      function(tk, c)
        return tk .. c == str:sub(1, #tk + 1)
      end,
      function(tk)
        return tk == str
      end
    }
  end,
  print = print,
  string = string, table = table,
  pairs = pairs, ipairs = ipairs,
  tonumber = tonumber, math = math,
  globalenv = _G, type = type,
}

-- basic ""reader""
local function reader(text)
  local chars = {}
  for c in text:gmatch(".") do
    chars[#chars+1] = c
  end

  local i = 0
  return {
    advance = function()
      i = i + 1
      return chars[i]
    end,
    backpedal = function()
      i = math.max(0, i - 1)
    end
  }
end

-- Takes a file and returns a builder.
function lib.new(file)
  local definitions = assert(loadfile(file, "t", syntenv))()

  for _, _defs in pairs(definitions) do
    for i, ent in pairs(_defs) do
      if type(ent) == "string" then
        _defs[i] = syntenv.char(ent)
      end
    end
  end

  return function(text)
    local read = reader(text)
    local possibilities = {}
    local aux = ""

    -- find and return the most likely (aka, longest) token and its class
    local function most_likely()
      -- if there are no possibilities, then ...
      if #possibilities == 0 then
        -- ... if the aux value has some characters, return that ...
        if #aux > 0 then
          local result = aux
          aux = ""
          return result
        else
          -- ... otherwise return nil.
          return nil
        end
      end

      local former_longest, new_longest = 0, 0

      -- remove all invalid possibilites
      for i=#possibilities, 1, -1 do
        if not possibilities[i].valid(possibilities[i].token) then
          former_longest = math.max(#possibilities[i].token, former_longest)
          table.remove(possibilities, i)
        else
          new_longest = math.max(#possibilities[i].token, new_longest)
        end
      end

      if former_longest > new_longest then
        for _=new_longest, former_longest - 1 do
          read.backpedal()
        end
      end

      -- sort possibilities by length - and deprioritize whitespace/word
      table.sort(possibilities, function(a, b)
        return #a.token > #b.token
            or (#a.token == #b.token and b.class == "word")
            or b.class == "whitespace"
      end)

      if #possibilities == 0 then
        --read.backpedal()
        return most_likely()
      end

      -- grab the first (longest) one
      local token, class = possibilities[1].token, possibilities[1].class
      -- reset possibilities
      possibilities = {}

      aux = ""

      -- return it
      return token, class
    end

    -- return an iterator!
    return function()
      while true do
        local c = read.advance()

        -- if no character, return the most likely token
        if not c then return most_likely() end

        if #possibilities == 0 then
          -- if no current possibilities, then go through and check for them
          for class, defs in pairs(definitions) do
            for _, funcs in pairs(defs) do
              if funcs[1](c) then
                -- if the token is valid, add it here
                possibilities[#possibilities+1] = {
                  check = funcs[2], class = class, token = c,
                  valid = funcs[3] or function()return true end, active = true
                }
              end
            end
          end

          -- if there are now some possibilities, return whatever the "aux"
          -- value was
          if #possibilities > 0 then
            if #aux > 0 then
              local temp = aux--:sub(1,-2)
              aux = ""
              return temp
            end
            aux = c
          else
            -- otherwise, add c to the aux value
            aux = aux .. c
          end
        else
          aux = aux .. c
          -- whether any possibilities matched
          local valid_for_any = false

          for _, p in ipairs(possibilities) do
            -- 'active' is roughly equal to whether the last character matched
            if p.active then
              -- if valid, set valid_for_any to true and add c to its valid
              if p.check(p.token, c) then
                valid_for_any = true
                p.token = p.token .. c
              else
                -- otherwise, disable it from future checks
                p.active = false
              end
            end
          end

          -- if nothing was valid, retract the current character
          -- and return the most likely token
          if not valid_for_any then
            read.backpedal()
            return most_likely()
          end
        end
      end
    end
  end
end

return lib
