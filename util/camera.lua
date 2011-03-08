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

-- The body to follow
local myBody = {}
-- Border awareness
local minX = {}
local maxX = {}
local screenX = {}
local minY = {}
local maxY = {}
local screenY = {}
local zoom = {}

camera = class:new(...)

--Assigns the borders of the game and the current body to follow
function camera:init(aCoordBag, aBody)
	minX,maxX,screenX,minY,maxY,screenY = aCoordBag:getCoords()
	myBody = aBody
	zoom = 1
end

--Allows the camera to jump to another body if needed.
function camera:assign(aBody)
	myBody = aBody
end

--Adjust the current position of the camera.
function camera:adjust()
	local currentX = ((maxX*zoom - screenX)/2) + (myBody:getX()*zoom - (maxX*zoom/2))
	local currentY = ((maxY*zoom - screenY)/2) + (myBody:getY()*zoom - (maxY*zoom/2))
	if(currentX < minX) then
		currentX = minX
	end
	if(currentX > (maxX*zoom - screenX)) then
		currentX = maxX*zoom - screenX
	end
	if(currentY < minY) then
		currentY = minY
	end
	if(currentY > (maxY*zoom - screenY)) then
		currentY = maxY*zoom - screenY
	end
	return currentX, currentY, zoom
end

function camera:keypressed(key)
	if(key == "1") then
		zoom = zoom + 0.25
		if(zoom >= 2) then
			zoom = 2
		end
	elseif(key == "2") then
		zoom = zoom - 0.25
		if(zoom <= 0.25) then
			zoom = 0.25
		end
	end
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
