local syn = {
  whitespace = {
    {
      function(c)
        return c:match("[ \n\r\t]")
      end,
      function()
        return false
      end,
      function(c)
        return c:match("^[ \n\r\t]+")
      end
    },
  },
  word = {
    {
      function(c)
        return not not c:match("[a-zA-Z_]")
      end,
      function(_, c)
        return not not c:match("[a-zA-Z_0-9]")
      end
    }
  },
  keyword = {
    "const", "close", "local", "while", "for", "repeat", "until", "do", "if",
    "in", "else", "elseif", "and", "or", "not", "then", "end", "return",
    "goto", "break",
  },
  builtin = {
    "function",
  },
  separator = {
    ",", "(", ")", "{", "}", "[", "]",
  },
  operator = {
    "+", "-", "/", "*", "//", "==", ">>", "<<", ">", "<", "=", "&",
    "|", "^", "%", "~", "...", "..", "~=", "#", ".", ":"
  },
  boolean = {
    "true", "false", "nil"
  },
  comment = {
    {
      function(c)
        return c == "-"
      end,
      function(t,c)
        if t == "-" and c ~= "-" then return false end
        return c ~= "\n"
      end,
      function(t)
        return #t > 1
      end
    },
    {
      function(c)
        return c == "-"
      end,
      function(t,c)
        if t == "-" and c == "-" then return true
        elseif t == "--" and c == "[" then return true
        elseif t == "--[" and c == "=" and c == "[" then return true
        elseif t:match("^%-%-%[(=*)$") and c == "=" and c == "[" then
          return true
        end
        local eqs = t:match("^%-%-%[(=*)")
        if not eqs then
          return false
        else
          if #t == #eqs + 3 and c == "[" then return true end
          if t:sub(-(#eqs+2)) == "]"..eqs.."]" then
            return false
          else
            return true
          end
        end
      end,
      function(t)
        return #t > 3
      end
    }
  },
  string = {
    {
      function(c)
        return c == "'" or c == '"'
      end,
      function(t, c)
        local first = t:sub(1,1)
        local last = t:sub(#t)
        local penultimate = t:sub(-2, -2)
        if #t == 1 then return true end
        if first == last and penultimate ~= "\\" then return false end
        return true
      end
    },
    {
      function(c)
        return c == "["
      end,
      function(t,c)
        if t == "[" then
          return c == "=" or c == "["
        elseif t:match("^%[(=*)$") and (c == "=" or c == "[") then
          return true
        end
        local eqs = t:match("^%[(=*)")
        if not eqs then
          return false
        else
          if #t == #eqs + 3 and c == "[" then return true end
          if t:sub(-(#eqs+2)) == "]"..eqs.."]" then
            return false
          else
            return true
          end
        end
      end,
      function(t)
        return #t > 2
      end
    }
  },
  number = {
    {
      function(c)
        return not not tonumber(c)
      end,
      function(t, c)
        return not not tonumber(t .. c .. "0")
      end
    }
  }
}

local seen = {}
local function add(k, v)
  if not v then return end
  if seen[v] then return end
  seen[v] = true
  for _k, _v in pairs(v) do
    syn.builtin[#syn.builtin+1] = char((k and k.."." or "").._k)
    if type(_v) == "table" then
      add((k and k.."." or "").._k, _v)
    end
  end
end

add(nil, globalenv)

return syn
