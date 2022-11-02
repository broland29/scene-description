-- this module's job is (mainly) parsing the LSD file and processing the 
--  data storing it for later use in query.lua (executed only once)

VERBOSE = false -- only helps with debugging, keep false during testing
INTRO = true    -- text before calling the query, keep true during testing

local lsd =  {}

require("vector")
require("box")
require("sphere")
require("face")
require("camera")


-- possible LSD block types
UNKNOWN = 0
CAMERA = 1
SCENE = 2

-- store all objects from the scene
lsd.sceneTable = {}   

-- Expected entries of cameraTable
--    loc = location of camera, point                            - vector
--    lookat = looking direction, point                          - vector
--    upis = reference up vector ("up is")                       - vector
--    dfrontplane = Dmin, distance from loc to front plane       - float
--    dbackplane = Dmax, distance from loc to back plane         - float
--    halfangle = half of field of view, presumably in angles    - float
--    rho = aspect ratio = Rmax / Umax                           - float
lsd.cameraTable = {}

-- keeping track of number of particular shapes
-- essential since testing requires printing objects in the order they were found
--  => they need to be indexed as such
lsd.shapeCount = 0

-- keep track of numbert of anonymous shapes, for name generation
anonFaceNum = 0
anonSphereNum = 0
anonBoxNum = 0


-- get a vector from a string like "(-1.2,3,4.4)"
function lsd.getVector(str)
  -- remove every whitespace (even carriage return)
  str = string.gsub(str, "%s", "")
  
  -- we use _ to throw away return values (start and end index of find)
  -- %( is an escaped ( symbol    -? means 0 or 1 - sign (negative or positive) 
  -- real numbers: whole part + dot (needs to be escaped) + frac. part
  -- we only keep the captures: ([+-real number],([+-real number],([+-real number])
  local _, _, x, y, z = string.find(str, "%((-?%d+%.?%d*),(-?%d+%.?%d*),(-?%d+%.?%d*)%)")
  return Vector.new(x, y, z)
end


-- process a line of camera block
function lsd.processCamera(line)
  
  if VERBOSE and line == nil then
    print("Got empty line in processCamera()")
    return
  end
  
  for pair in string.gmatch(line, "[^;]+") do
    if(string.match(pair,"%w+") == nil) then
      if VERBOSE then print("Got nothing useful in pair, will result in nil k and v; processCamera") end
      break  -- not sure how to avoid this, my barbarian solution may be error prone
    end

    local k, v
    _, _, k, v = string.find(pair, "(%w+)%s*=%s*(.*)")
    
    -- treat vector values with special care
    if (k == "loc" or k == "lookat" or k == "upis") then
      lsd.cameraTable[k] = lsd.getVector(v)
    else
      lsd.cameraTable[k] = v
    end
  end
end


-- get a sphere from a "sphere-line"
function lsd.processSphere(parameters)
  local ctr = nil
  local rad = nil
  local name = nil
  local color = nil

  -- iterate through all substrings starting with? one or more ;-s (pairs)
  for pair in string.gmatch(parameters, "[^;]+") do
    
    if(string.match(pair,"%w+") == nil) then
      if VERBOSE then print("Got nothing useful in pair, will result in nil k and v; sphere") end
      break  -- not sure how to avoid this, my barbarian solution may be error prone
    end
    
    local k, v    -- [1-* alphanumeric][0-* whitespace]=[0-* whitespace][0-* anything]
    _, _, k, v = string.find(pair, "(%w+)%s*=%s*(.*)")
    
    if k == "ctr" then
      ctr = lsd.getVector(v)
    elseif k == "rad" then
      rad = v
    elseif k == "name" then
      name = v
    elseif k == "col" then
      color = v
    else 
      print(string.format("Cannot handle sphere property %s", k))
    end
  end
  
  if name == nil then
    anonSphereNum = anonSphereNum + 1
    name = "sphere#"..anonSphereNum
    if INTRO then io.write(string.format("Auto-generated: %s\n",name)) end
  end
  
  if color == nil then
    color = "NotSpectifiedColor"
  end
  
  return Sphere.new(ctr,rad,name,color)
end


-- get a face from a "face-line"
-- TODO: what is face normal?
function lsd.processFace(parameters) 
  local verts = nil
  local name = nil
  local col = nil
  
  -- iterate through all substrings starting with one or more ;-s (pairs)
  for pair in string.gmatch(parameters, "[^;]+") do
    
    if(string.match(pair,"%w+") == nil) then
      if VERBOSE then print("Got nothing useful in pair, will result in nil k and v; face") end
      break  -- not sure how to avoid this, my barbarian solution may be error prone
    end

    local k, v    -- [1-i alphanumeric][0-i whitespace]=[0-i whitespace][0-i any]
    _, _, k, v = string.find(pair, "(%w+)%s*=%s*(.*)")
    
    if k == "verts" then
      verts = {}
      
      -- NEED TO ESCAPE MINUS SIGN !!! (unlike when we actually captured the coordinates [this realization costed some headaches])
      for w in string.gmatch(v,"%(%-?%d+%.?%d*,%-?%d+%.?%d*,%-?%d+%.?%d*%)") do 
        table.insert(verts,lsd.getVector(w))
      end
    elseif k == "name" then
      name = v
    elseif k == "col" then
      col = v
    else 
      print(string.format("Cannot handle face property %s", k))
    end
  end

  if name == nil then
    anonFaceNum = anonFaceNum + 1
    name = "face#"..anonFaceNum
    if INTRO then io.write(string.format("Auto-generated: %s\n",name)) end
  end
  
  if color == nil then
    color = "NotSpectifiedColor"
  end

  return Face.new(verts,name,col)
end


-- get a box from a "box-line"
function lsd.processBox(parameters)
  local blf = nil
  local trb = nil
  local name = nil
  local color = nil
  
  -- iterate through all substrings starting with one or more ;-s (pairs)
  for pair in string.gmatch(parameters, "[^;]+") do
    
    if(string.match(pair,"%w+") == nil) then
      if VERBOSE then print("Got nothing useful in pair, will result in nil k and v; box") end
      break  -- not sure how to avoid this, my barbarian solution may be error prone
    end

    local k, v    -- [1-i alphanumeric][0-i whitespace]=[0-i whitespace][0-i any]
    _, _, k, v = string.find(pair, "(%w+)%s*=%s*(.*)")
    
    if k == "blf" then
      blf = lsd.getVector(v)
    elseif k == "trb" then
      trb = lsd.getVector(v)
    elseif k == "name" then
      name = v
    elseif k == "col" then
      color = v
    else 
      print(string.format("Cannot handle sphere property %s", k))
    end
  end
  
  if name == nil then
    anonBoxNum = anonBoxNum + 1
    name = "box#"..anonBoxNum
    if INTRO then io.write(string.format("Auto-generated: %s\n",name)) end
  end
  
  if color == nil then
    color = "NotSpectifiedColor"
  end
  
  return Box.new(blf,trb,name,color)
end


-- process a line of sphere block
function lsd.processScene(line)
  -- [any number of white space] [type] [w.s.] : [w.s] [parameters]
  local type, parameters = string.match(line, "^%s*(%w+)%s*:%s*(.*)")

  -- again, a not-so-elegant solution
  if (type == nil) then
    if (VERBOSE) then print("Invalid type") end
    return
  end
  if (parameters == "") then
    if (VERBOSE) then print("Invalid parameters") end
    return
  end
  
  -- create the object of appropriate type and put it in the scene table
  if type == "sphere" then
    lsd.shapeCount = lsd.shapeCount + 1
    local sphere = lsd.processSphere(parameters) 
    lsd.sceneTable[lsd.shapeCount] = sphere
    
  elseif type == "face" then
    lsd.shapeCount = lsd.shapeCount + 1
    local face = lsd.processFace(parameters)       
    lsd.sceneTable[lsd.shapeCount] = face		
  
  elseif type == "box" then
    lsd.shapeCount = lsd.shapeCount + 1
    local box = lsd.processBox(parameters)      
    lsd.sceneTable[lsd.shapeCount] = box
  
  else
    print(string.format("Cannot handle objects of type %s; ignoring...", type))
  end
end 


-- the function which ties lsd.lua together, a.k.a reading a whole file
function lsd.read(fileName)
  -- open the file, if cannot find, assert generates error
  file = assert(io.open(fileName,"r"),"Input file not found.")
  
  blockType = UNKNOWN
  
  for line in file:lines() do
    -- delete comments: start with [#] and continue with [0 to inf] number of [any characters]
    line = string.gsub(line,"#.*","")
    
    if blockType == CAMERA then
      if string.find(line, "^aremac") then
        if INTRO then io.write(string.format("end of camera block\n")) end
        
        -- last thing we print in "intro", has an extra endline (note that this implies camera block is last one)
        if lsd.cameraTable["w"] ~= nil and lsd.cameraTable["h"] ~= nil then
          lsd.cameraTable["spec"] = "WH"
          if INTRO then print(string.format("Camera frontplane specified by width / height\n")) end
        elseif lsd.cameraTable["halfangle"] ~= nil and lsd.cameraTable["rho"] ~= nil then
          lsd.cameraTable["spec"] = "HR"
          if INTRO then print(string.format("Camera frontplane specified by halfangle / ratio\n")) end
        else
          if INTRO then print(string.format("Camera not specified properly\n")) end
        end
        -- exited camera block
        blockType = UNKNOWN
      else
        -- inside camera block
        lsd.processCamera(line)
      end
      
    elseif blockType == SCENE then
      if string.find(line, "^enecs") then
        if INTRO then io.write(string.format("end of scene block\n")) end
        -- exited scene block
        blockType = UNKNOWN
      else
        -- inside scene block
        lsd.processScene(line)
      end    
    
    -- blockType = UNKNOWN
    elseif string.find(line, "^camera") then
      if INTRO then io.write(string.format("found camera block\n")) end
      -- entered camera block
      blockType = CAMERA 
    elseif string.find(line, "^scene") then
      if INTRO then io.write(string.format("found scene block\n")) end
      -- entered scene block
      blockType = SCENE 
    end 
  end
  
  -- close the file (good practice)
  io.close(file)
end


return lsd
