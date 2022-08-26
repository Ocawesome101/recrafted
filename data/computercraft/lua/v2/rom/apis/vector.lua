-- rc.vector

local vector = {}
local Vector = {}

function Vector:add(o)
  return vector.new(self.x + o.x, self.y + o.y, self.z + o.z)
end

function Vector:sub(o)
  return vector.new(self.x - o.x, self.y - o.y, self.z - o.z)
end

function Vector:mul(m)
  return vector.new(self.x * m, self.y * m, self.z * m)
end

function Vector:div(m)
  return vector.new(self.x / m, self.y / m, self.z / m)
end

function Vector:unm()
  return vector.new(-self.x, -self.y, -self.z)
end

function Vector:dot(o)
  return (self.x * o.x) + (self.y * o.y) + (self.z * o.z)
end

function Vector:cross(o)
  return vector.new(
    (self.y * o.z) - (self.z * o.y),
    (self.z * o.x) - (self.x * o.z),
    (self.x * o.y) - (self.y * o.x))
end

function Vector:length()
  return math.sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z))
end

function Vector:normalize()
  return self:div(self:length())
end

function Vector:round(tolerance)
  tolerance = tolerance or 1
  local squared = tolerance * tolerance
  return vector.new(
    math.floor(self.x + (tolerance * 0.5)) / squared,
    math.floor(self.y + (tolerance * 0.5)) / squared,
    math.floor(self.z + (tolerance * 0.5)) / squared)
end

function Vector:tostring()
  return string.format("%d,%d,%d", self.x, self.y, self.z)
end

function Vector:equals(o)
  return self.x == o.x and self.y == o.y and self.z == o.z
end

Vector.eq = Vector.equals

local vect_mt = {
  __index = Vector
}

for k, v in pairs(Vector) do
  vect_mt["__"..k] = v
end

function vector.new(x, y, z)
  return setmetatable({x = x or 0, y = y or 0, z = z or 0}, vect_mt)
end

return vector
