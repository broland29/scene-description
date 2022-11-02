-- this module contrains the functions which execute various queries
-- previous data is needed from parsed file (through lsd.lua)

local query = {}


lsd = require("lsd")
require("vector")
require("matrix")


-- "write to the screen a list of all of the objects that you know about"
function query.whatObjects()
  t = lsd.sceneTable
  io.write(string.format("%d known objects:\n", lsd.shapeCount))
  for k, v in pairs(lsd.sceneTable) do
    io.write(string.format("Name: %s; type: %s\n",t[k].name,t[k]:getType()))
  end
end


-- "write to the screen the camera specifications as read from the input file"
function query.cameraParams()
  local t = lsd.cameraTable
  io.write(string.format("Camera location: %s\n", t["loc"]:niceForm()))
  io.write(string.format("Camera looking at: %s\n", t["lookat"]:niceForm()))
  io.write(string.format("Camera up direction (approx.): %s\n", t["upis"]:niceForm()))
  io.write(string.format("Camera dist to frontplane: %.3f\n", t["dfrontplane"]))
  io.write(string.format("Camera dist to backplane: %.3f\n", t["dbackplane"]))
  
  if t["spec"] == "WH" then
    io.write(string.format("Camera frontplane width: %.3f\n", t["w"]))
    io.write(string.format("                  height: %.3f\n", t["h"]))  
  elseif t["spec"] == "HR" then
    io.write(string.format("Camera frontplane halfange: %.3f\n", t["halfangle"]))
    io.write(string.format("                  ratio: %.3f\n", t["rho"]))
  else
    assert(false,"Unexpexted lsd.cameraTable[\"spec\"] entry")
  end
end


-- auxiliary function to get the camera coordinate system bases
function getDUR()
  -- D is the direction in which we look
  local D = Vector.subtract(lsd.cameraTable["lookat"],lsd.cameraTable["loc"])
  D:normalize()
  
  -- R can be found by using the reference up direction
  local R = Vector.cross(D, lsd.cameraTable["upis"])
  R:normalize()
  
  -- from here U is just one cross product away; no need to normalize
  local U = Vector.cross(R,D)
  return D, U, R
end


-- "write to the screen the three camera normalised directions D, U and R"
function query.directions()
  local D, U, R = getDUR()
  
  io.write(string.format("Directions: D=%s\n",D:niceForm()))
  io.write(string.format("            U=%s\n",U:niceForm()))
  io.write(string.format("            R=%s\n",R:niceForm()))
end


-- gets data about frustum vertices in camera and world coordinates, and 
--  about its planes (normals and points which define them); see: lecture 5
function getFrustum()
  
  local dMax, dMin, uMax, uMin, rMax, rMin
  dMax = lsd.cameraTable["dbackplane"]
  dMin = lsd.cameraTable["dfrontplane"]
  
  if lsd.cameraTable["spec"] == "WH" then
    uMax = lsd.cameraTable["h"] / 2
    rMax = lsd.cameraTable["w"] / 2
  elseif lsd.cameraTable["spec"] == "HR" then 
    uMax = dMin * math.tan(lsd.cameraTable["halfangle"] * (math.pi / 180))
    rMax = lsd.cameraTable["rho"] * uMax
  end
  
  uMin = -1 * uMax
  rMin = -1 * rMax
  
  local dur = {}  -- table to store information in D-U-R coordinate system (camera)
  local xyz = {}  -- table to store information in X-Y-Z coordinate system (world)
  
  dur["e"] = Vector.new(0, 0, 0)      -- in D-U-R, point of origin is 0
  xyz["e"] = lsd.cameraTable["loc"]   -- in X-Y-Z, point of origin is given in camera description  
  
  local factor = dMax / dMin
  
  local minminmin = Vector.new(dMin, uMin , rMin)
  local minmaxmin = Vector.new(dMin, uMax , rMin)
  local minminmax = Vector.new(dMin, uMin , rMax)
  local minmaxmax = Vector.new(dMin, uMax , rMax)
  
  dur["vbl"] = Vector.add(dur["e"], minminmin)
  dur["vtl"] = Vector.add(dur["e"], minmaxmin) 
  dur["vbr"] = Vector.add(dur["e"], minminmax)
  dur["vtr"] = Vector.add(dur["e"], minmaxmax)
  
  minminmin = minminmin:scale(factor)
  minminmax = minminmax:scale(factor)
  minmaxmin = minmaxmin:scale(factor)
  minmaxmax = minmaxmax:scale(factor)
  
  dur["wbl"] = Vector.add(dur["e"], minminmin)
  dur["wtl"] = Vector.add(dur["e"], minmaxmin) 
  dur["wbr"] = Vector.add(dur["e"], minminmax)
  dur["wtr"] = Vector.add(dur["e"], minmaxmax)
  
  
  local D, U, R = getDUR()

  -- going from D-U-R to X-Y-Z using change of basis matrix
  --  getting from one basis to another is a linear transformation in our case
  --  as it turned out, it is the transpose of DUR
  --                 XYZ = cob * DUR
  --        XYZ * DUR^-1 = cob
  
  dur["base"] = Matrix.new(D, U, R)
  
  xyz["base"] = Matrix.new(
    Vector.new(1, 0, 0),
    Vector.new(0, 1, 0),
    Vector.new(0, 0, 1))
  
  cob = Matrix.multiply(xyz["base"], dur["base"]:inverse())
  
  xyz["vbl"] = Vector.add(xyz["e"], cob:multiplyVector(dur["vbl"]))
  xyz["vtl"] = Vector.add(xyz["e"], cob:multiplyVector(dur["vtl"]))
  xyz["vbr"] = Vector.add(xyz["e"], cob:multiplyVector(dur["vbr"]))
  xyz["vtr"] = Vector.add(xyz["e"], cob:multiplyVector(dur["vtr"]))
  xyz["wbl"] = Vector.add(xyz["e"], cob:multiplyVector(dur["wbl"]))
  xyz["wtl"] = Vector.add(xyz["e"], cob:multiplyVector(dur["wtl"]))
  xyz["wbr"] = Vector.add(xyz["e"], cob:multiplyVector(dur["wbr"]))
  xyz["wtr"] = Vector.add(xyz["e"], cob:multiplyVector(dur["wtr"]))
  
  
  -- a plane is defined by a normal (n) and a point on it (p)
  -- choosing the points is easy: just choose from the already known points
  local fr = {}
  local ba = {}
  local to = {}
  local bo = {}
  local le = {}
  local ri = {}
  fr["p"] = dur["vbr"]
  ba["p"] = dur["wbl"]
  to["p"] = dur["e"]
  bo["p"] = dur["e"]
  le["p"] = dur["e"]
  ri["p"] = dur["e"]
  
  -- getting normals: we cross two vectors on the corresponding plane
  --  order matters, we want normal to point inwards
  local n = {}
  fr["n"] = Vector.cross(
    Vector.subtract(dur["vtl"],dur["vtr"]),
    Vector.subtract(dur["vtl"],dur["vbl"]))
  fr["n"]:normalize()
  
  ba["n"] = Vector.cross(
    Vector.subtract(dur["wtl"],dur["wbl"]),
    Vector.subtract(dur["wtl"],dur["wtr"]))
  ba["n"]:normalize()
  
  to["n"] = Vector.cross(
    Vector.subtract(dur["vtl"],dur["e"]),
    Vector.subtract(dur["vtr"],dur["e"]))
  to["n"]:normalize()
  
  bo["n"] = Vector.cross(
    Vector.subtract(dur["vbr"],dur["e"]),
    Vector.subtract(dur["vbl"],dur["e"]))
  bo["n"]:normalize()
   
  le["n"] = Vector.cross(
    Vector.subtract(dur["vbl"],dur["e"]),
    Vector.subtract(dur["vtl"],dur["e"]))
  le["n"]:normalize()
  
  ri["n"] = Vector.cross(
    Vector.subtract(dur["vtr"], dur["e"]),
    Vector.subtract(dur["vbr"], dur["e"]))
  ri["n"]:normalize()
  
  -- group all planes of frustum into one table
  planes = {}
  planes["fr"] = fr
  planes["ba"] = ba
  planes["to"] = to
  planes["bo"] = bo
  planes["le"] = le
  planes["ri"] = ri
  
  return dur, xyz, planes
end


-- print data about the frustum
function query.frustum()
  local dur, xyz, planes = getFrustum()
  
  io.write(string.format("In (d,u,r) co-ords v_bl= %s\n", dur["vbl"]:niceForm()))
  io.write(string.format("                   v_tl= %s\n", dur["vtl"]:niceForm()))
  io.write(string.format("                   v_br= %s\n", dur["vbr"]:niceForm()))
  io.write(string.format("                   v_tr= %s\n", dur["vtr"]:niceForm()))
  io.write(string.format("                   w_bl= %s\n", dur["wbl"]:niceForm()))
  io.write(string.format("                   w_tl= %s\n", dur["wtl"]:niceForm()))
  io.write(string.format("                   w_br= %s\n", dur["wbr"]:niceForm()))
  io.write(string.format("                   w_tr= %s\n", dur["wtr"]:niceForm()))
  
  io.write(string.format("In (x,y,z) co-ords v_bl= %s\n", xyz["vbl"]:niceForm()))
  io.write(string.format("                   v_tl= %s\n", xyz["vtl"]:niceForm()))
  io.write(string.format("                   v_br= %s\n", xyz["vbr"]:niceForm()))
  io.write(string.format("                   v_tr= %s\n", xyz["vtr"]:niceForm()))
  io.write(string.format("                   w_bl= %s\n", xyz["wbl"]:niceForm()))
  io.write(string.format("                   w_tl= %s\n", xyz["wtl"]:niceForm()))
  io.write(string.format("                   w_br= %s\n", xyz["wbr"]:niceForm()))
  io.write(string.format("                   w_tr= %s\n", xyz["wtr"]:niceForm()))
  
  io.write(string.format("The frustrum planes: front: n=%s; p=%s\n", planes["fr"]["n"]:niceForm(), planes["fr"]["p"]:niceForm()))
  io.write(string.format("                      back: n=%s; p=%s\n", planes["ba"]["n"]:niceForm(), planes["ba"]["p"]:niceForm()))
  io.write(string.format("                       top: n=%s; p=%s\n", planes["to"]["n"]:niceForm(), planes["to"]["p"]:niceForm()))
  io.write(string.format("                    bottom: n=%s; p=%s\n", planes["bo"]["n"]:niceForm(), planes["bo"]["p"]:niceForm()))
  io.write(string.format("                      left: n=%s; p=%s\n", planes["le"]["n"]:niceForm(), planes["le"]["p"]:niceForm()))
  io.write(string.format("                     right: n=%s; p=%s\n", planes["ri"]["n"]:niceForm(), planes["ri"]["p"]:niceForm()))
end


-- a plane is defined by a point (p0) and a normal vector, which is normalized! here (n)
-- dot product of n and p1-p0 is the signed distance of point p1 from the plane
-- dot product involves cosine, which is positive if in 1st or 4th quadrant of unit circle
--    => d.p. is positive if the two vectors point in the same direction, negative if not
function distance(plane, p1)
  return Vector.dot(plane["n"], Vector.subtract(p1, plane["p"]))
end

--function checkToPlanes(p, n, )

--function pointInFrustum(plane, p1)
  
--end

function checkSphereVisibility(sphere, planes)
  local d
  local res = "inside" 
  
  for pk, pv in pairs(planes) do
    -- print(string.format("index: %s; n: %s; p: %s", pk, pv["n"]:niceForm(), pv["p"]:niceForm()))
    
    d = distance(pv, sphere.ctr)
    print(string.format("Distance from center to %s: %f ; r = %f", pk, d, sphere.rad))
    
    -- https://stackoverflow.com/questions/73532887/attempt-to-compare-number-with-string-lua
    -- print("Rad: ",sphere.rad, "Tonum: ",tonumber(sphere.rad))
    if d < -1 * tonumber(sphere.rad) then
      return "outside"
    elseif d < tonumber(sphere.rad) then
      res = "intersect"
    end
    
    print("Debug: ", res)
  end
  
  return res
end

function checkBoxVisibility(box, planes)
  local d
  local res = "inside"
  local hasIn = false
  local hasOut = false
  for pk, pv in pairs(planes) do
    -- TODO: CONT
    d = distance(pv, sphere.ctr)
  end
end

function query.visible()
  local dur, _, planes = getFrustum()
  t = lsd.sceneTable
  
  io.write(string.format("Visible objects:\n"))
  
  for k, v in pairs(t) do
    type = t[k].getType()
    
    if (type == "face") then
      print("Found face "..t[k].name)
      --[[
      
      -- check vertices
      -- all the distances should be positive, meaning that the point is
      --  on the positive side of all of the frustum's planes
      -- one - means its outside, while ALL + means inside
      for k, v in pairs(t[k].verts) do
        -- what if no vertex inside but edge still inside
        print(string.format("\npoint %s: %s", k, v:niceForm()))
  
        for pk, pv in pairs(planes) do
          print(string.format("index: %s; n: %s; p: %s", pk, pv["n"]:niceForm(), pv["p"]:niceForm()))
          d = distance(pv, v)
          print(string.format("distance: %d",d))
        end
        -- Point 2 seems to be inside, meaning that the face is partially visible? contradiction with expected output
      end
      
      -- todo check edges 
      
      -- todo check if aligned ?
    
    ]]--
    elseif (type == "box") then
      print("Found box "..t[k].name)
      
      --[[
      for k, v in pairs(t[k].verts) do
        -- what if no vertex inside but edge still inside
        print(string.format("point %s: %s", k, v:niceForm()))
  
        dfr = distance(n["fr"], p["fr"], v)
        dba = distance(n["ba"], p["ba"], v)
        dto = distance(n["to"], p["to"], v)
        dbo = distance(n["bo"], p["bo"], v)
        dle = distance(n["le"], p["le"], v)
        dri = distance(n["ri"], p["ri"], v)
        
        -- Point 2 seems to be inside, meaning that the face is partially visible? contradiction with expected output
        print(string.format("dfr:%d\ndba:%d\ndto:%d\ndbo:%d\ndle:%d\ndri:%d",dfr,dba,dto,dbo,dle,dri))
      end
      
      -- todo check edges 
      
      -- todo check if aligned ?
    ]]--
  elseif (type == "sphere") then
      hasInside = false
      hasOutside = false
      
      print("\n\nFound sphere ".. v.name)
      res = checkSphereVisibility(v, planes)
      print(res)
    
    else
      print("Unknown type "..type)
    end
  end
end

return query
