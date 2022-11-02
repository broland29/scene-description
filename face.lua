-- module modelling a face class
-- useful for grouping together data related to a face object

Face = {}
Face.__index = Face


--  Constructor
--    - verts = vertices defining face  - table of vectors
--    - name and color                  - string
function Face.new(verts, name, color)
  local instance = setmetatable({}, Face)
  
  assert(verts ~= nil, "Verts not specified!")
  assert(type(verts) == "table", "Verts not a table!")
  for k,v in pairs(verts) do
    assert(type(v) == "table" and v["getType"] ~= nil and v:getType() == "vector", "Verts contains non-vector elements!")
  end
 
  assert(name ~= nil, "Name not specified!")
  assert(color ~= nil, "Color not specified!")
  assert(type(name) == "string", "Name is not a string!")
  assert(type(color) == "string", "Color is not a string!")
  
  instance.name = name
  instance.color = color
  instance.verts = verts
  
  return instance
end

-- diplays data of face, for debugging purposes
function Face:display()
  print("---- Face -----")
  
  print("Verts:")
  for vk, vv in pairs(self.verts) do
    print(string.format("vertex %s: %s", vk, vv:niceForm()))
  end
  print(string.format("Name: %s\nColor: %s", self.name, self.color))
  
  print("---------------")
end

-- returns "class" of "object"
function Face:getType()
  return "face"
end