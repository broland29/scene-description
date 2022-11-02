-- module modelling a box class
-- useful for grouping together data related to a box object

Box = {}
Box.__index = Box


-- Constructor 
--    - blf = bottom-left-front corner - vector
--    - trb = top-right-back corner    - vector
--    - name and color                 - string
function Box.new(blf, trb, name, color)
  local instance = setmetatable({}, Box)
  
  assert(blf ~= nil, "BLF not specified!")
  assert(trb ~= nil, "TRB not specified!")
  assert(type(blf) == "table" and blf["getType"] ~= nil and blf:getType() == "vector", "BLF is not a vector!")
  assert(type(trb) == "table" and trb:getType() == "vector", "TRB is not a vector!")
  
  assert(name ~= nil, "Name not specified!")
  assert(color ~= nil, "Color not specified!")
  assert(type(name) == "string", "Name is not a string!")
  assert(type(color) == "string", "Color is not a string!")
  
  instance.name = name
  instance.color = color

  instance.vert = {}        -- store vertices in a table
  instance.vert["blf"] = blf
  instance.vert["trb"] = trb
  -- the other 6 vertices derive from blf and trb
  instance.vert["blb"] = Vector.new(blf.x, blf.y, trb.z)
  instance.vert["brb"] = Vector.new(blf.x, trb.y, trb.z)
  instance.vert["brf"] = Vector.new(blf.x, trb.y, blf.z)  --
  instance.vert["trf"] = Vector.new(trb.x, trb.y, blf.z)
  instance.vert["tlf"] = Vector.new(trb.x, blf.y, blf.z)
  instance.vert["tlb"] = Vector.new(trb.x, blf.y, trb.z)
  
  return instance
end

-- diplays data of box, for debugging purposes
function Box:display()
  print("----- Box -----")
  
  print("Vertices: ")
  for vk, vv in pairs(self.vert) do
    print(string.format("vertex %s: %s", vk, vv:niceForm()))
  end
  print(string.format("Name: %s\nColor: %s", self.name, self.color))

  print("---------------")
end

-- returns "class" of "object"
function Box:getType()
  return "box"
end
