--[[
Copyright (c) 2011 Team Tempest

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

functions.lua

This static class contains common functions (no state or side effects).
This includes distance functions, angle functions, and the ability to copy a table.

These functions do not directly fulfill requirements.
They aid in various calculations and adjustments throughout the program.
--]]

--[[
--Find the distance between two ordered pairs of points.
--1 is the origin point, 2 is the destination point.
--]]
function pointDistance( x1, y1, x2, y2 )
    return hypotenuse( x2 - x1, y2 - y1 )
end

--[[
--Find the angle in radians between two ordered pairs of points.
--1 is the origin point, 2 is the destination point.
--]]
function pointAngle( x1, y1, x2, y2 )
    return math.atan2( y2 - y1, x2 - x1 )
end

--[[
--Find the hypotenuse of two vectors.
--Called by pointDistance, which has already derived the vectors.
--]]
function hypotenuse( x, y )
    return ( x ^ 2 + y ^ 2 ) ^ ( 1 / 2 )
end

--[[
--Creates a shallow copy of a lua table, and returns it.
--]]
function copyTable( aTable )
    local newTable = {}
    for key, value in pairs( aTable ) do
        newTable[ key ] = value
    end
    return setmetatable( newTable, getmetatable( aTable ) )
end

--[[
-- Returns the nearest object in objects list to given coordinates
-- assumed object is a game object, that has active state and a body
-- if owner is provided, object owned by owner will be ignored
--
-- Requirement 14
--]]
function nearest( x, y, objects, owner )
	local nearestObject = {}
	local nearestDistance = 999999
	local nearestAngle = -1
	if objects ~= nil then -- only search if something to search in
		local tempX = 0
		local tempY = 0
		local tempDist = 0
		for i, anObject in ipairs( objects ) do
			if owner == nil or owner and anObject.owner ~= owner then
				if anObject.isActive == true then -- check only active objects
					local tempX = anObject.body:getX()
					local tempY = anObject.body:getY()
					local tempDist = pointDistance( x, y, tempX, tempY )
					if tempDist < nearestDistance then
						nearestObject = anObject
						nearestDistance = tempDist
						nearestAngle = pointAngle( x, y, tempX, tempY )
					end
				end
			end
		end
	end
	return nearestObject, nearestDistance, nearestAngle
end
