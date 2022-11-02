-- module modelling a vector class
-- useful for grouping together data related to a vector
-- helps in building bigger objects, encapsulates vector operations

Vector = {}
Vector.__index = Vector

FILTER_MINUS_ZERO = true  -- replace -0s with 0s


-- Constructor
--    - x, y, z coordinates of vector
function Vector.new(x, y, z)
  local instance = setmetatable({}, Vector)
  
  -- make sure we store numbers
  x = tonumber(x)
  y = tonumber(y)
  z = tonumber(z)
  assert(x ~= nil, "X not specified properly!")
  assert(y ~= nil, "Y not specified properly!")
  assert(z ~= nil, "Z not specified properly!")
  
  if FILTER_MINUS_ZERO then
    if x == -0 then x = 0 end 
    if y == -0 then y = 0 end
    if z == -0 then z = 0 end
  end
  
  instance.x = x
  instance.y = y
  instance.z = z
  
  return instance
end

-- diplays data of vector, for debugging purposes
function Vector:display()
  print(string.format("(%f,%f,%f)",self.x,self.y,self.z))
end

-- string format of data of vector, in format approved by tests
function Vector:niceForm()
  return string.format("(%.3f,%.3f,%.3f)",self.x,self.y,self.z)
end


-- returns a vector = v1 - v2
function Vector.subtract(v1,v2)
  return Vector.new(
    v1.x - v2.x,
    v1.y - v2.y,
    v1.z - v2.z)
end


-- returns length of vector
function Vector:length()
  return math.sqrt(
    self.x * self.x +
    self.y * self.y +
    self.z * self.z)
end


-- normalizes vector
function Vector:normalize()
  local length = self:length()
  if length == 0 then return end  -- cannot normalize null vector
  self.x = self.x / length
  self.y = self.y / length
  self.z = self.z / length
end


-- returns a vector = v1 x v2
function Vector.cross(v1,v2)
  return Vector.new(
    v1.y * v2.z - v1.z * v2.y,
    v1.z * v2.x - v1.x * v2.z,
    v1.x * v2.y - v1.y * v2.x)
end


-- returns a vector = v1 + v2
function Vector.add(v1,v2)
  return Vector.new(
    v1.x + v2.x,
    v1.y + v2.y,
    v1.z + v2.z)
end


-- returns a vector = v1 * num (scalar)
function Vector:scale(num)
  return Vector.new(
    self.x * num,
    self.y * num,
    self.z * num)
end


-- -- returns a vector = v1 . v2
function Vector.dot(v1,v2)
  return
    v1.x * v2.x +
    v1.y * v2.y +
    v1.z * v2.z
end


-- returns "class" of "object"
function Vector:getType()
  return "vector"
end