-- module modelling a sphere class
-- useful for grouping together data related to a sphere object

Sphere = {}
Sphere.__index = Sphere


-- Constructor
--    - ctr = center      - vector
--    - rad = radius      - vector
--    - name and color    - string
function Sphere.new(ctr, rad, name, color)
  local instance = setmetatable({}, Sphere)
  
  assert(ctr ~= nil, "Ctr not specified!")
  assert(type(ctr) == "table" and ctr:getType() == "vector", "Ctr is not a vector!")
  rad = tonumber(rad)
  assert(rad ~= nil, "Rad not specified properly!")
  
  assert(name ~= nil, "Name not specified!")
  assert(color ~= nil, "Color not specified!")
  assert(type(name) == "string", "Name is not a string!")
  assert(type(color) == "string", "Color is not a string!")
  
  instance.name = name
  instance.color = color
  instance.ctr = ctr
  instance.rad = rad
  
  return instance
end

-- diplays data of sphere, for debugging purposes
function Sphere:display()
  print("--- Sphere ----")
  print(string.format("ctr: %s\nrad: %f\nname: %s\ncolor: %s",
      self.ctr:niceForm(),
      self.rad,
      self.name,
      self.color))
  print("---------------")
end

-- returns "class" of "object"
function Sphere:getType()
  return "sphere"
end