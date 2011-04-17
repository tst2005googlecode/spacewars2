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

camera = class:new(...)

--[[
--Creates and initializes a camera for the game.
--Assigns boundaries, the focus object, and camera controls.
--]]
function camera:construct(aCoordBag, aBody, aConfigBag)
	--Hold the boundaries of the world and window for movement.
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
	--Center the camera on the assigned body at default scale.
	self.myBody = aBody
	self.zoom = 1
	--Assign the zoom keys.
	self.zoomIn = aConfigBag:getZoomIn()
	self.zoomOut = aConfigBag:getZoomOut()
end

--[[
--Allows the camera to jump to another body if needed.
--]]
function camera:assign(aBody)
	self.myBody = aBody
end

--[[
--Checks the key to see if it is a valid control.
--Allows the camera to support zoom in and zoom out functions.
--]]
function camera:keypressed(key)
	if key == self.zoomIn then
		self.zoom = self.zoom + 0.125
		if self.zoom > 2 then --Limit zoom at 200%
			self.zoom = 2
		end
	elseif key == self.zoomOut then
		self.zoom = self.zoom - 0.125
		if self.zoom < 0.125 then --Limit zoom at 12.5%
			self.zoom = 0.125
		end
	end
end

--[[
--Adjust the current position of the camera.
--Returns the position to draw from, and the current zoom level.
--
--This verision of camera:adjust() assumes scaling occurs before tranlating
--Since love.graphics.print ASSUMES scale occurs before translating, this IS text-safe.
--]]
function camera:adjust()
	local currentX = ((self.maxX - self.screenX/self.zoom) / 2) + (self.myBody:getX() - (self.maxX / 2))
	local currentY = ((self.maxY - self.screenY/self.zoom) / 2) + (self.myBody:getY() - (self.maxY / 2))
	if currentX < self.minX then
		currentX = self.minX
	elseif currentX > (self.maxX - self.screenX/self.zoom) then
		currentX = self.maxX - self.screenX/self.zoom
	end
	if currentY < self.minY then
		currentY = self.minY
	elseif currentY > (self.maxY - self.screenY/self.zoom) then
		currentY = self.maxY - self.screenY/self.zoom
	end
	self.x = currentX
	self.y = currentY
	return currentX, currentY, self.zoom
end

--[[
--Return the X coordinate of the camera without updating.
--]]
function camera:getX()
	return self.x
end

--[[
--Returns the Y coordinate of the camera without updating.
--]]
function camera:getY()
	return self.y
end

--[[
--Returns the zoom level of the camera without updating.
--]]
function camera:getZoom()
	return self.zoom
end


--WARNING: OLD CODE NOT IN USE.  CURRENTLY ARCHIVED.

--[[
-- This version of camera:adjust() assumes love.graphics.transform occurs before love.graphics.scale
-- Since love.graphics.print ASSUMES scale occurs before transfrom, this IS NOT text-safe.
function camera:adjust()
	local currentX = ((self.maxX * self.zoom - self.screenX) / 2) + (self.myBody:getX() * self.zoom - (self.maxX * self.zoom / 2))
	local currentY = ((self.maxY * self.zoom - self.screenY) / 2) + (self.myBody:getY() * self.zoom - (self.maxY * self.zoom / 2))
	if currentX < self.minX then
		currentX = self.minX
	end
	if currentX > (self.maxX * self.zoom - self.screenX) then
		currentX = self.maxX * self.zoom - self.screenX
	end
	if currentY < self.minY then
		currentY = self.minY
	end
	if currentY > (self.maxY * self.zoom - self.screenY) then
		currentY = self.maxY * self.zoom - self.screenY
	end
	return currentX, currentY, self.zoom
end
--]]

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
