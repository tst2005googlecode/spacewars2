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
The radar has an x and y offset for drawing on the screen.
The radar covers a radius from the center, which is the playerShip.
	For simplicity, the radius is figured on x/y axis, and drawn as a box.
The scale of the radar is the diameter divided by the radar's size.
--]]
require "util/camera.lua"
radar = class:new(...)

--The width and height of the radar
local size = 100

--Colors used to build the radar
local frameColor = {255,255,255}
local bgColor = {0,0,0,128}
local playerColor = {255,255,255}
local aiColor = {255,0,0}
local missileColor = {255,165,0}
local solarColor = {34,139,34}

function radar:init(theRadius,theBody)
	self.offX = 0
	self.offY = 0
	self.radius = theRadius
	self.body = theBody
	self.scale = (self.radius*2)/size
end

--[

function radar:draw(obj_table)
	love.graphics.setColor(frameColor)
	love.graphics.rectangle("line",self.offX,self.offY,size+50,size+50)
	love.graphics.setColor(bgColor)
	love.graphics.rectangle("fill",self.offX+1,self.offY+1,size+48,size+48)
	for i,obj in ipairs(obj_table) do
		theType = obj:getType()
		if(theType == "solarMass") then
			love.graphics.setColor(solarColor)
			self:drawSolar(obj)
		elseif(theType == "playerShip") then
			love.graphics.setColor(playerColor)
			self:drawGeneric(obj)
		elseif(theType == "aiShip") then
			love.graphics.setColor(aiColor)
			self:drawGeneric(obj)
		elseif(theType == "missile") then
			love.graphics.setColor(missileColor)
			self:drawGeneric(obj)
		end
	end
end

function radar:drawGeneric(obj)
	local x = obj:getX()
	local y = obj:getY()
	local theRad = 1
	if(self:checkBounds(x,y) == true) then
		x = (obj:getX() - self.body:getX() + self.radius)/self.scale
		y = (obj:getY() - self.body:getY() + self.radius)/self.scale
		love.graphics.circle("fill",self.offX + x, self.offY + y, theRad, 10)
	end
end

function radar:drawSolar(obj)
	local x = obj:getX()
	local y = obj:getY()
	local theRad = obj:getRadius()
	if(self:checkBounds(x,y) == true) then
		x = (obj:getX() - self.body:getX() + self.radius)/self.scale
		y = (obj:getY() - self.body:getY() + self.radius)/self.scale
		theRad = theRad/self.scale
		if(theRad < 1) then theRad = 1 end
		love.graphics.circle("fill",self.offX + x, self.offY + y, theRad, 10)
	end
end

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
