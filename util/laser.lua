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

This class implements a laser beam (simulated by particle) which will cause 
damage to impacted targets.
--]]

require "subclass/class.lua"
require "util/bodyObject.lua"

local color = {}
local source = {}

laser = bodyObject:new(...)

function laser:construct( aWorld, x, y, startAngle, aCoordBag, aSource, velX, velY )
	 -- technically, light shouldn't have mass, but can't be 0 or won't move
	self:constructBody( aWorld, x, y, 0.0000000001, 0 )
	self.body:setBullet( true )
	self.laserShape = love.physics.newPolygonShape( self.body, 0, 0.5, 200, 0.5, 200, -0.5, 0, -0.5 )
	--self.laserShape = love.physics.newCircleShape( self.body, 0, 0, 0.5 )
	self.laserShape:setData(self)
	self.objectType = types.laser

	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()

	self.data = {}
	
	self:init( aWorld, x, y, startAngle, aCoordBag, aSource, velX, velY )
end

function laser:init( aWorld, x, y, startAngle, aCoordBag, aSource, velX, velY )
	if self.body:isFrozen() then
		-- get a new body ... the old one can no longer be used!!  :(
		self.body:destroy()
		self:constructBody( aWorld, x, y, 0.0000000001, 0 )
	end
	self.body:setAngle( startAngle )
	self.body:setPosition( x, y )
	self.body:wakeUp()
	self.laserShape:setSensor( true )
	self.body:setLinearVelocity( velX, velY )
	self.source = aSource
	self.color = aSource.color
end

function laser:draw()
	local angle = pointAngle( self.body:getX(), self.body:getY(), self.source.body:getX(), self.source.body:getY() )
	local x2 = math.cos( angle ) * 200
	local y2 = math.sin( angle ) * 200
	love.graphics.setColor( unpack( self.color ) )
	love.graphics.setLine( 1, "smooth" )
	love.graphics.polygon("fill", self.laserShape:getPoints())
	--love.graphics.line( self.body:getX(), self.body:getY(), self.body:getX() + x2, self.body:getY() + y2 )
	--love.graphics.line( self.body:getX(), self.body:getY(), self.source.body:getX(), self.source.body:getY() )
end

function laser:update(dt)
	if self:offedge() == true then
		self:destroy()
	end
end

function laser:destroy()
	if self.isActive == false then -- has to stay in position once to draw beam
		self.body:setPosition( -math.random( 10, 100 ), math.random( 10, 10000 ) )
		return
	end
	self.laserShape:setSensor( false )
	self.body:putToSleep()
	self:deactivate()
	self.data.status = "DEAD"
	-- set motion and position to zero, or will still move in the world
	self.body:setLinearVelocity( 0, 0 )
--	self.body:setPosition( 0,0 )
	lasers:recycle( self )
end

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

function laser:getOwner()
	return self.data.owner
end

function laser:setOwner( own )
	self.data.owner = own
end

function laser:getStatus()
	return self.data.status
end

function laser:setStatus( stat )
	self.data.status = stat
end

function laser:getX()
	return self.body:getX()
end

function laser:getY()
	return self.body:getY()
end

function laser:getType()
	return "laser"
end
