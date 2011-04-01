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

debris.lua

This class implements free-floating debris.
--]]

require "subclass/class.lua"

debris = class:new(...)
local color = {205,133,63,255}

function debris:init(aWorld, aCoordBag)
	self.coord = aCoordBag
	self.world = aWorld
	self.data = {}
	self:respawn()
end

function debris:draw()
	love.graphics.setColor(color)
	love.graphics.polygon("fill",self.shape:getPoints())
end

function debris:update(dt)
	if(self.data.status == "DEAD") then
		self:respawn()
	else
		self:warp()
	end
end

function debris:respawn()
	local border = math.random(1,4)
	if (border == 1) then
		local x = self.coord:getMaxX()
		local y = math.random(0,self.coord:getMaxY())
		self:build(x,y)
		local xVel = math.random(-80,-10)
		local yVel = math.random(-80,80)
		self.body:setLinearVelocity(xVel,yVel)
	elseif (border == 2) then
		local x = math.random(0,self.coord:getMaxX())
		local y = self.coord:getMaxY()
		self:build(x,y)
		local xVel = math.random(-80,80)
		local yVel = math.random(-80,-10)
		self.body:setLinearVelocity(xVel,yVel)
	elseif (border == 3) then
		local x = self.coord:getMinX()
		local y = math.random(0,self.coord:getMaxY())
		self:build(x,y)
		local xVel = math.random(10,80)
		local yVel = math.random(-80,80)
		self.body:setLinearVelocity(xVel,yVel)
	else
		local x = math.random(0,self.coord:getMaxX())
		local y = self.coord:getMinY()
		self:build(x,y)
		local xVel = math.random(-80,80)
		local yVel = math.random(10,80)
		self.body:setLinearVelocity(xVel,yVel)
	end
	self.data.status = "DEBRIS"
	self.shape:setData(self.data)
	self.shape:setSensor(true)
	self.holdTime = 5
end

function debris:warp()
	if(self.body:getX() > self.coord:getMaxX()) then
		self.body:setX(self.coord:getMinX())
	end
	if(self.body:getX() < self.coord:getMinX()) then
		self.body:setX(self.coord:getMaxX())
	end
	if(self.body:getY() > self.coord:getMaxY()) then
		self.body:setY(self.coord:getMinY())
	end
	if(self.body:getY() < self.coord:getMinY()) then
		self.body:setY(self.coord:getMaxY())
	end
end

function debris:build(x,y)
	self.body = love.physics.newBody(self.world, x, y, 30, 1)
	self.shape = love.physics.newRectangleShape(self.body, 0, 0, 15, 15, 0)
end

function debris:getBody()
	return self.body
end

function debris:getX()
	return self.body:getX()
end

function debris:getY()
	return self.body:getY()
end

function debris:getType()
	return "debris"
end
