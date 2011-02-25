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

camera.lua

This class implements a camera that follows a body.
It will attempt to keep the body in the center of the screen.
When the camera reaches the edge of the applicable game board, it stops.
--]]

require "subclass/class.lua"

local myBody = {}
camera = class:new(...)

function camera:init(aBody)
	myBody = aBody
end

function camera:adjust(minX, maxX, screenX, minY, maxY, screenY)
	local currentX = ((maxX - screenX)/2) + (myBody:getX() - (maxX/2))
	local currentY = ((maxY - screenY)/2) + (myBody:getY() - (maxY/2))
	if(currentX < minX) then
		currentX = minX
	end
	if(currentX > (maxX - screenX)) then
		currentX = maxX - screenX
	end
	if(currentY < minY) then
		currentY = minY
	end
	if(currentY > (maxY - screenY)) then
		currentY = maxY - screenY
	end
	return currentX, currentY
end

--Old camera code, keeping just in case
--[[	if(theBody:getX() + screenX > screenX * 0.8) then
		if(theBody:getX() < maxX - screenX * 0.2) then
			screenX = screenX - math.abs(xVelocity)
		end
	end
	if (theBody:getX() + screenX < screenX * 0.2) then
		if(theBody:getX() > screenX * 0.2) then
			screenX = screenX + math.abs(xVelocity)
		end
	end
	if (theBody:getY() + screenY > screenY * 0.8) then
		if(theBody:getY() < maxY - screenY * 0.2) then
			screenY = screenY - math.abs(yVelocity)
		end
	end
	if (theBody:getY() + screenY < screenY * 0.2) then
		if(theBody:getY() > screenY * 0.2) then
			screenY = screenY + math.abs(yVelocity)
		end
	end --]]
