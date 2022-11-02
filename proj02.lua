-- Computer Graphics Project no.2
-- Bálint Roland

-- Bibliography:
-- https://www.tutorialspoint.com/lua/lua_modules.htm
-- https://www.youtube.com/watch?v=g1iKA3lSFms
-- https://snippets.bentasker.co.uk/page-1908111120-Check-if-variable-is-numeric-LUA.html
-- https://stackoverflow.com/questions/13081620/for-each-loop-in-a-lua-table-with-key-value-pairs
-- https://stackoverflow.com/questions/70730820/lua-check-if-method-exists
-- http://garryowen.csisdmz.ul.ie/~cs4085/resources/cs4085-lect05.pdf


query = require("query")
lsd = require("lsd")

lsd.read(arg[1])

print("whatObjects():")
query.whatObjects()

print("cameraParams()")
query.cameraParams()

print("directions()")
query.directions()

print("frustum()")
query.frustum()

print("visible()")
query.visible()
