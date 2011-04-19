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

radar.lua

This class implements a radar system.
The radar covers a radius from the center, which is the player's ship.
	For simplicity, the radius is figured on x/y axis, and drawn as a box.
The scale of the radar is the diameter divided by the radar's size.
--]]
require "util/camera.lua"
require "subclass/class.lua"
radar = class:new(...)

--The width and height of the radar
local size = 120

--Colors used to build the radar
local frameColor = {255,255,255,255}
local bgColor = {0,0,0,128}
local playerColor = {255,255,255,255}
local aiColor = {255,0,0,255}
local playerMissileColor = {255,255,0,255}
local aiMissileColor = {255,140,0,255}
local solarColor = {34,139,34,255}
local debrisColor = {0,191,255,255}

--[[
--Constructs and initializes a radar.
--]]
function radar:construct(theRadius,theBody)
	self.offX = 0
	self.offY = 0
	self.radius = theRadius
	self.body = theBody
	self.scale = (self.radius*2)/size
end

--[[
--Draws the radar using the current list of active objects.
--]]
function radar:draw(obj_table)
	--Draw the frame.
	love.graphics.setColor(frameColor)
	love.graphics.rectangle("line",self.offX,self.offY,size+10,size+10)
	--Draw the background with 50% opacity.
	love.graphics.setColor(bgColor)
	love.graphics.rectangle("fill",self.offX+1,self.offY+1,size+9,size+9)
	--Iterate through all active objects
	for i,obj in ipairs(obj_table) do
		local x = obj:getX()
		local y = obj:getY()
		if(self:checkBounds(x,y) == true) then
			--Proceed with drawing the object to the radar.
			theType = obj:getType()
			if(theType == "solarMass") then
				--Draw a solarMass
				love.graphics.setColor(solarColor)
				self:drawSolar(obj)
			elseif(theType == "playerShip") then
				--Draw a player
				love.graphics.setColor(playerColor)
				self:drawGeneric(obj)
			elseif(theType == "aiShip") then
				--Draw an ai
				love.graphics.setColor(aiColor)
				self:drawGeneric(obj)
			elseif(theType == "missile") then
				--Draw a missile
				if(obj:getOwner():getControl() == "P") then
					love.graphics.setColor(playerMissileColor)
				else
					love.graphics.setColor(aiMissileColor)
				end
				self:drawGeneric(obj)
			elseif(theType == "debris") then
				--Draw a debris
				love.graphics.setColor(debrisColor)
				self:drawGeneric(obj)
			end
		end
	end
end

--[[
--This is a function to draw generic objects.
--All non-solarMasses are very small, and so are drawn as a circle of radius 1.
--]]
function radar:drawGeneric(obj)
	local theRad = 1
	local x = (obj:getX() - self.body:getX() + self.radius)/self.scale
	local y = (obj:getY() - self.body:getY() + self.radius)/self.scale
	love.graphics.circle("fill",self.offX + x, self.offY + y, theRad, 10)
end

--[[
--This is a function to draw solarMass objects.
--A solarMass is drawn on the radar to scale.
--]]
function radar:drawSolar(obj)
	local theRad = obj:getRadius()
	local x = (obj:getX() - self.body:getX() + self.radius)/self.scale
	local y = (obj:getY() - self.body:getY() + self.radius)/self.scale
	theRad = theRad/self.scale
	if(theRad < 1) then theRad = 1 end
	love.graphics.circle("fill",self.offX + x, self.offY + y, theRad, 10)
end

--[[
--Check if an object is within the boundaries of the radar's scan radius.
--If it is, return true, and the radar will draw it.
--Otherwise, it returns false, and the object is skipped this cycle.
--]]
function radar:checkBounds(x,y)
	if(x >= (self.body:getX() - self.radius)) then
		if(x <= (self.body:getX() + self.radius)) then
			if(y >= (self.body:getY() - self.radius)) then
				if(y <= (self.body:getY() + self.radius)) then
					return true
				end
			end
		end
	end
	return false
end

--WARNING: The following are old or alternative implementations and should not be used.


--[[ THIS VERSION OF DRAWPLAYER/SOLAR RENDERS THE ENTIRE WORLD IN THE RADAR
function radar:drawPlayer(obj)
	local x = obj:getX()
	local y = obj:getY()
	local theRad = 1
	x = x/self.scale
	y = y/self.scale
	love.graphics.circle("fill",self.offX + x, self.offY + y, theRad, 10)
end

function radar:drawSolar(obj)
	local x = obj:getX()
	local y = obj:getY()
	local theRad = obj:getRadius()
	x = x/self.scale
	y = y/self.scale
	theRad = theRad/self.scale
	if(theRad < 1) then theRad = 1 end
	love.graphics.circle("fill",self.offX + x, self.offY + y, theRad, 10)
	love.graphics.print("65535",self.offX,self.offY)
end
--]]

--[[ POTENTIAL CODE TO USE WITH A FRAMEBUFFER?
function radar:draw(obj_table)
	love.graphics.setRenderTarget(self.theBuffer)
	local currentX, currentY = self.theCamera:adjust()
	love.graphics.scale(self.scale,self.scale)
	love.graphics.translate(-currentX,-currentY)
	for i, obj in ipairs( obj_table ) do
		theType = obj:getType()
		if(theType == "playerShip") then
			love.graphics.setColor(255,255,255)
		elseif(theType == "solarMass") then
			love.graphics.setColor(34,139,34)
		end
		obj:draw()
	end
	love.graphics.setRenderTarget()
	love.graphics.setColor(255,255,255)
	love.graphics.rectangle("line",0,0,110,110)
	love.graphics.draw(self.theBuffer,5,5)
end
--]]
