-- rc.copy - table copier

-- from https://lua-users.org/wiki/CopyTable
local function deepcopy(orig, copies, dont_copy)
  copies = copies or {}
  local orig_type = type(orig)
  local copy

  if orig_type == 'table' and not dont_copy[orig] then
    if copies[orig] then
      copy = copies[orig]
    else
      copy = {}
      copies[orig] = copy

      for orig_key, orig_value in next, orig, nil do
        copy[deepcopy(orig_key, copies, dont_copy)] = deepcopy(orig_value,
          copies, dont_copy)
      end

      setmetatable(copy, deepcopy(getmetatable(orig), copies, dont_copy))
    end
  else -- number, string, boolean, etc
    copy = orig
  end

  return copy
end

return { copy = function(original, ...)
  local dont_copy = {}
  for _, thing in pairs({...}) do
    dont_copy[thing] = true
  end
  return deepcopy(original, nil, dont_copy)
end }
