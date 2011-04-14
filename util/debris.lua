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

debris = bodyObject:new(...)

local color = {205,133,63,255}
local mass = 0

function debris:construct(aWorld, aCoordBag, location, x, y)
	self.coord = aCoordBag
	self.world = aWorld
	self.data = {}
	self.objectType = types.debris
	self.body = love.physics.newBody(self.world, 0, 0, 1, 1)
	self.shape = love.physics.newRectangleShape( self.body, 0, 0, 12, 12, math.random() * maxAngle)
	self.shape:setData( self )

	self:init( aWorld, aCoordBag, location, x, y )
end

function debris:init(aWorld, aCoordBag, location, x, y)
	self.mass = math.random(100000,100000000)
	self.body:setMass( 0, 0, self.mass, self.mass * ( 100000 ^ 2 ) / 6 )
	self.body:wakeUp()
	self.isActive = true
	if(location == "border") then
		self:respawnBorder()
	elseif(location == "ship") then
		self:respawnShip(x,y)
	else
		self:respawnRandom()
	end
	self.shape:setData(self)
	self.shape:setSensor( true )
	self.data.status = ""
end

function debris:draw()
	love.graphics.setColor(color)
	love.graphics.polygon("fill",self.shape:getPoints())
end

function debris:update(dt)
	self:warp()
end

function debris:respawnBorder()
	local border = math.random(1,4)
	if (border == 1) then
		self.body:setX(self.coord:getMaxX())
		self.body:setY(math.random(0,self.coord:getMaxY()))
--		self:build(x,y)
		local xVel = math.random(-80,-10)
		local yVel = math.random(-80,80)
		self.body:setLinearVelocity(xVel,yVel)
	elseif (border == 2) then
		local x = math.random(0,self.coord:getMaxX())
		local y = self.coord:getMaxY()
--		self:build(x,y)
		local xVel = math.random(-80,80)
		local yVel = math.random(-80,-10)
		self.body:setLinearVelocity(xVel,yVel)
	elseif (border == 3) then
		self.body:setX(self.coord:getMinX())
		self.body:setY(math.random(0,self.coord:getMaxY()))
--		self:build(x,y)
		local xVel = math.random(10,80)
		local yVel = math.random(-80,80)
		self.body:setLinearVelocity(xVel,yVel)
	else
		self.body:setX(math.random(0,self.coord:getMaxX()))
		self.body:setY(self.coord:getMinY())
--		self:build(x,y)
		local xVel = math.random(-80,80)
		local yVel = math.random(10,80)
		self.body:setLinearVelocity(xVel,yVel)
	end
end

function debris:respawnShip(x,y)
	self.body:setX(x)
	self.body:setY(y)
	local xVel = math.random(-80,80)
	local yVel = math.random(-80,80)
	self.body:setLinearVelocity(xVel,yVel)
end

function debris:respawnRandom()
	local x = math.random(0,6400)
	local y = math.random(0,6400)
	local xSide = math.random(0,1)
	local ySide = math.random(0,1)
	if(xSide == 0) then
		self.body:setX(self.coord:getMinX() + x)
	else
		self.body:setX(self.coord:getMaxX() - x)
	end
	if(ySide == 0) then
		self.body:setY(self.coord:getMinY() + y)
	else
		self.body:setY(self.coord:getMaxY() - y)
	end
	local xVel = math.random(-80,80)
	local yVel = math.random(-80,80)
	self.body:setLinearVelocity(xVel,yVel)
end

function debris:destroy()
	self.shape:setSensor( false )
	self.body:putToSleep()
	self:deactivate()
	self.data.status = "DEAD"
	-- set motion and postiont to zero, or will still move in the world
	self.body:setLinearVelocity( 0, 0 )
	self.body:setPosition( -math.random( 10, 100 ), math.random( 10, 10000 ) )
	junk:recycle( self )
end

function debris:warp()
	if(self.body:getX() > self.coord:getMaxX()) then
		self.body:setX(self.coord:getMinX())
	elseif(self.body:getX() < self.coord:getMinX()) then
		self.body:setX(self.coord:getMaxX())
	end
	if(self.body:getY() > self.coord:getMaxY()) then
		self.body:setY(self.coord:getMinY())
	elseif(self.body:getY() < self.coord:getMinY()) then
		self.body:setY(self.coord:getMaxY())
	end
end
--[[
function debris:build(x,y)
	self.body = love.physics.newBody(self.world, x, y, 30, 1)
	self.shape = love.physics.newRectangleShape( self.body, 0, 0, 12, 12, math.random() * maxAngle )
end
--]]
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
