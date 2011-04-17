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

laser.lua

This class implements a laser beam which will cause damage to impacted targets.
Lasers are rectangular in shape.
Lasers spawn near the ship and travel in a predetermined straight line.
	BUG: One update occurs before first draw.
		 They DO cause collisions on that update, but they are not drawn.
Lasers are aware of the borders of the world.
	They self-destruct upon exceeding a world border.
The laser currently does 1 damage/millisecond of application.
	This damage is dynamically calculated on every update.
--]]

require "subclass/class.lua"
require "util/bodyObject.lua"

local color = {}
local source = {}

laser = bodyObject:new(...)

--[[
--Construct a laser if a recycled instance does not exist.
--Sets border awareness, constructs the body/shape, and sets it as a bullet.
--Ends by calling the init function.
--]]
function laser:construct( aWorld, x, y, startAngle, aCoordBag, aSource, velX, velY )
	--Light shouldn't have mass, but a mass of 0 is forced to be stationary.
	self:constructBody( aWorld, x, y, 0.0000000001, 0 )
	--Lasers move quickly, this forces collision if it "jumps" something.
	self.body:setBullet( true )
	self.laserShape = love.physics.newPolygonShape( self.body, 0, 0.5, 200, 0.5, 200, -0.5, 0, -0.5 )
	--Set the laser's data.
	self.data = {}
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
	self.laserShape:setData(self)
	self.objectType = types.laser

	self:init( aWorld, x, y, startAngle, aCoordBag, aSource, velX, velY )
end

--[[
--Initialize a newly created or recycled instance of laser.
--Sets the laser's spawn location, velocity, and angle of movement.
--Sets the laser up for use in the game engine.
--]]
function laser:init( aWorld, x, y, startAngle, aCoordBag, aSource, velX, velY )
	if self.body:isFrozen() then
		--Get a new body, the old one can no longer be used!!  :(
		self.body:destroy()
		self:constructBody( aWorld, x, y, 0.0000000001, 0 )
	end
	--Setup the laser for simulation in the world.
	self:activate()
	self.body:setPosition( x, y )
	self.body:wakeUp()
	self.laserShape:setSensor( true )
	--Set the speed and direction of the laser.
	self.body:setAngle( startAngle )
	self.body:setLinearVelocity( velX, velY )
	--Set the owner of the laser and its color.
	self.source = aSource
	self.color = aSource.color
	--Set an "average" damage number in case of instant collision.
	self.data.damage = 20
end

--[[
--Draws the laser on the screen, using its owner's color.
--WARNING: Because lasers are large, they will be drawn "through" an object on collision.
--]]
function laser:draw()
--	local angle = pointAngle( self.body:getX(), self.body:getY(), self.source.body:getX(), self.source.body:getY() )
--	local x2 = math.cos( angle ) * 200
--	local y2 = math.sin( angle ) * 200
	love.graphics.setColor( unpack( self.color ) )
--	love.graphics.setLine( 1, "smooth" )
	love.graphics.polygon("fill", self.laserShape:getPoints())
--	love.graphics.line( self.body:getX(), self.body:getY(), self.body:getX() + x2, self.body:getY() + y2 )
--	love.graphics.line( self.body:getX(), self.body:getY(), self.source.body:getX(), self.source.body:getY() )
end

--[[
--Updates the laser in the world.
--Since update rates change constantly, damage is recalculated each cycle.
--When a laser goes off the edge, it is immediately destroyed.
--]]
function laser:update(dt)
	self.data.damage = dt*1000
	if self:offedge() == true then
		self:destroy()
	end
end

--[[
--When a laser is destroyed, it needs to be cleaned up.
--This function disables simulation in the game world.
--Finally, it adds the laser to the recycle bag for use later.
--]]
function laser:destroy()
	if self.isActive == false then
		--Has to stay in position once to draw beam
		self.body:setPosition( -math.random( 10, 100 ), math.random( 10, 10000 ) )
		return
	end
	--Set the laser to stop simulation in the world.
	self.laserShape:setSensor( false )
	self.body:putToSleep()
	self:deactivate()
	self.data.status = "DEAD"
	--Set velocity to 0 before it destructs.
	self.body:setLinearVelocity( 0, 0 )
--	self.body:setPosition( 0,0 )
	--Put it in the recycle bin for later use.
	lasers:recycle( self )
end

--[[
--Checks to see if the laser has exceeded a world boundary.
--If so, then it returns true, so the update method destroys the laser.
--Otherwise, it returns false, which will cause nothing to happen.
--]]
function laser:offedge()
	if(self.body:getX() > self.maxX) then
		return true
	end
	if(self.body:getX() < self.minX) then
		return true
	end
	if(self.body:getY() > self.maxY) then
		return true
	end
	if(self.body:getY() < self.minY) then
		return true
	end
	return false
end

--[[
--Gets the owner of the laser.
--]]
function laser:getOwner()
	return self.data.owner
end

--[[
--Sets the owner of the laser.
--]]
function laser:setOwner( own )
	self.data.owner = own
end

--[[
--Gets the status of the laser.
--]]
function laser:getStatus()
	return self.data.status
end

--[[
--Sets the status of the laser.
--]]
function laser:setStatus( stat )
	self.data.status = stat
end

--[[
--Gets the X coordinate of the laser.
--]]
function laser:getX()
	return self.body:getX()
end

--[[
--Gets the Y coordinate of the laser.
--]]
function laser:getY()
	return self.body:getY()
end

--[[
--Gets the type of the laser, which is "laser".
--]]
function laser:getType()
	return "laser"
end
