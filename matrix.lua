-- module modelling a matrix class
-- useful for grouping together data related to a matrix
-- encapsulates matrix operations

Matrix = {}
Matrix.__index = Matrix


-- Constructor
--    - r1, r2, r3 = rows of matrix - vectors
function Matrix.new(r1, r2, r3)
  local instance = setmetatable({}, Matrix)
  
  assert(r1 ~= nil, "R1 not specified!")
  assert(r2 ~= nil, "R2 not specified!")
  assert(r3 ~= nil, "R3 not specified!")
  assert(type(r1) == "table" and r1:getType() == "vector", "R1 is not a vector!")
  assert(type(r2) == "table" and r2:getType() == "vector", "R2 is not a vector!")
  assert(type(r3) == "table" and r3:getType() == "vector", "R3 is not a vector!")
  
  instance.r1 = r1
  instance.r2 = r2
  instance.r3 = r3
  
  return instance
end


-- diplays data of matrix, for debugging purposes
function Matrix:display()
  self.r1:display()
  self.r2:display()
  self.r3:display()
end


-- return the determinant of matrix
function Matrix:determinant()
  return
    self.r1.x * self.r2.y * self.r3.z +
    self.r1.y * self.r2.z * self.r3.x +
    self.r1.z * self.r2.x * self.r3.y -
    self.r1.z * self.r2.y * self.r3.x -
    self.r1.y * self.r2.x * self.r3.z -
    self.r1.x * self.r2.z * self.r3.y
end


-- return the matrix = minors of matrix
function Matrix:minors()
  return Matrix.new(
    Vector.new(
      self.r2.y * self.r3.z - self.r2.z * self.r3.y,
      self.r2.x * self.r3.z - self.r2.z * self.r3.x,
      self.r2.x * self.r3.y - self.r2.y * self.r3.x),
    Vector.new(
      self.r1.y * self.r3.z - self.r1.z * self.r3.y,
      self.r1.x * self.r3.z - self.r1.z * self.r3.x,
      self.r1.x * self.r3.y - self.r1.y * self.r3.x),
    Vector.new(
      self.r1.y * self.r2.z - self.r1.z * self.r2.y,
      self.r1.x * self.r2.z - self.r1.z * self.r2.x,
      self.r1.x * self.r2.y - self.r1.y * self.r2.x))
end


-- return a matrix of minors with "checkerboard of minuses" applied on it
function Matrix:cofactors()
  m = self:minors()
  m.r1.y = -1 * m.r1.y
  m.r2.x = -1 * m.r2.x
  m.r2.z = -1 * m.r2.z
  m.r3.y = -1 * m.r3.y
  return m
end


-- return a matrix = transpose of matrix
function Matrix:transpose()
  return Matrix.new(
    Vector.new(self.r1.x, self.r2.x, self.r3.x),
    Vector.new(self.r1.y, self.r2.y, self.r3.y),
    Vector.new(self.r1.z, self.r2.z, self.r3.z))
end


-- return a matrix = adjoint (adjugate) of matrix
function Matrix:adjoint()
  m = self:cofactors()
  return m:transpose()
end


-- return a matrix = m1 * m2
function Matrix.multiply(m1, m2)
  -- extract columns of m2
  c1 = Vector.new(m2.r1.x, m2.r2.x, m2.r3.x)
  c2 = Vector.new(m2.r1.y, m2.r2.y, m2.r3.y)
  c3 = Vector.new(m2.r1.z, m2.r2.z, m2.r3.z)
  
  -- use previously defined dot product
  return Matrix.new(
    Vector.new(Vector.dot(m1.r1, c1), Vector.dot(m1.r1, c2), Vector.dot(m1.r1, c3)),
    Vector.new(Vector.dot(m1.r2, c1), Vector.dot(m1.r2, c2), Vector.dot(m1.r2, c3)),
    Vector.new(Vector.dot(m1.r3, c1), Vector.dot(m1.r3, c2), Vector.dot(m1.r3, c3)))
end


-- return a matrix = matrix * s (scalar)
function Matrix:scale(s)
  return Matrix.new(
    self.r1:scale(s),
    self.r2:scale(s),
    self.r3:scale(s))
end


-- return a matrix = inverse of matrix
function Matrix:inverse()
  onePerDet = 1 / self:determinant()
  adjoint = self:adjoint()
  return adjoint:scale(onePerDet)
end


-- return a matrix = matrix * vect ("3x1" vector => get "3x1" vector)
function Matrix:multiplyVector(vect)
  return Vector.new(
    self.r1.x * vect.x + self.r1.y * vect.y + self.r1.z * vect.z,
    self.r2.x * vect.x + self.r2.y * vect.y + self.r2.z * vect.z,
    self.r3.x * vect.x + self.r3.y * vect.y + self.r3.z * vect.z)
end