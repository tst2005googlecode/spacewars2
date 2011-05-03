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
Debris are square in shape.
Debris have three spawning methods, depending on desired start position.
Debris are aware of the borders of the world.
	They warp after exceeding the edge of the world.
Debris have 250 armor that must be depleted before destruction.
WARNING: Uses global junk table from game.lua.
--]]

require "subclass/class.lua"

debris = bodyObject:new(...)

local color = {205,133,63,255} --Brown

--[[
--Construct a debris if a recycled instance does not exist.
--Sets border awareness, constructs a generic body/shape, and sets object data.
--Ends by calling the init function.
--
--Requirement 10
--]]
function debris:construct(aWorld, aCoordBag, location, x, y, iVelx, iVelY, mass)
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
	self:constructBody( aWorld, 0, 0, 1, 1 )
	self.shape = love.physics.newRectangleShape( self.body, 0, 0, 12, 12, math.random() * maxAngle)
	self.data = {}
	self.shape:setData( self )
	self.objectType = types.debris

	self:init( aWorld, aCoordBag, location, x, y, iVelx, iVelY, mass )
end

--[[
--Initialize a newly constructed or recycled debris.
--Sets the debris' mass and a spawn location.
--Restores armor and sets the debris up for use in the game engine.
--
--Requirement 10
--]]
function debris:init(aWorld, aCoordBag, location, x, y, iVelx, iVelY, mass)
	if self.body:isFrozen() then
		--Get a new body, the old one can no longer be used!!  :(
		self.body:destroy()
		self:constructBody( aWorld, 0, 0, 1, 1 )
	end
	--Initialize mass.
	self.mass = math.random(100,100000)
	self.body:setMass( 0, 0, self.mass, self.mass * ( 100000 ^ 2 ) / 6 )
	--Setup the mass for simulation in the world.
	self.body:wakeUp()
	self:activate()
	self.shape:setSensor( true )
	--Choose a method for setting spawn position.
	if(location == "border") then
		self:respawnBorder()
	elseif(location == "ship") then
		self:respawnShip(x,y,iVelx,iVelY,mass)
	else
		self:respawnRandom()
	end
	--Initialize warping, armor, and damage.
	self.warpTimer = 0
	self.data.armor = 250
	self.data.damage = 250
	self.data.ore = math.random()
end

--[[
--Draws the debris on the screen, using the declared color constant.
--]]
function debris:draw()
	love.graphics.setColor(color)
	love.graphics.polygon("fill",self.shape:getPoints())
end

--[[
--Updates the debris in the world.
--Debris are removed from game area when out of bounds ... more will be created
--Debris are generally slow moving, therefore they only check once per second.
--This saves a good amount of processing time.
--]]
function debris:update(dt)
	--Add dt milliseconds to the timer.
	self.warpTimer = self.warpTimer + dt * 1000
	if(self.warpTimer > 1000) then
		-- check if out of bounds
		if (self.body:getX() > self.maxX) or (self.body:getX() < self.minX) or 
				(self.body:getY() > self.maxY) or (self.body:getY() < self.minY) then
			self:destroy()
		end
		self.warpTimer = 0
	end
end

--[[
--Allows a debris to respawn on the border of the world.
--Specified by setting location to "border" when calling construct/init.
--It chooses a border, then any position on the non-static axis.
--Finally, it sets velocity such that it always moves inward from spawn.
--
--Requirement 10.1
--]]
function debris:respawnBorder()
	local border = math.random(1,4)
	if (border == 1) then
		self.body:setX(self.maxX)
		self.body:setY(math.random(0,self.maxY))
		local xVel = math.random(-80,-10)
		local yVel = math.random(-80,80)
		self.body:setLinearVelocity(xVel,yVel)
	elseif (border == 2) then
		self.body:setX(0,self.maxX)
		self.body:setY(self.maxY)
		local xVel = math.random(-80,80)
		local yVel = math.random(-80,-10)
		self.body:setLinearVelocity(xVel,yVel)
	elseif (border == 3) then
		self.body:setX(self.minX)
		self.body:setY(math.random(0,self.maxY))
		local xVel = math.random(10,80)
		local yVel = math.random(-80,80)
		self.body:setLinearVelocity(xVel,yVel)
	else
		self.body:setX(math.random(0,self.maxX))
		self.body:setY(self.minY)
		local xVel = math.random(-80,80)
		local yVel = math.random(10,80)
		self.body:setLinearVelocity(xVel,yVel)
	end
end

--[[
--Allows a debris to spawn where a ship has been destroyed.
--Specified by setting location to "ship" when calling construct/init.
--It spawns at the position with a random X/Y velocity.
--
--Requirement 10.2
--]]
function debris:respawnShip(x,y,sVelX,sVelY,mass)
	self.body:setX(x)
	self.body:setY(y)
	local xVel = math.random(-80,80)
	local yVel = math.random(-80,80)
	self.body:setLinearVelocity( sVelX + xVel, sVelY + yVel )
	self.mass = mass
	self.body:setMass( 0, 0, self.mass, self.mass * ( 100000 ^ 2 ) / 6 )
end

--[[
--Allows a debris to spawn somewhere in the game world.
--This is the default spawn behavior if neither alternative is specified.
--This is specifically used when the game is first started.
--The debris spawns closest to the game borders, radially from the planet
--It spawns with a random X/Y velocity.
--
--Requirement 10.1
--]]
function debris:respawnRandom()
	local angle = math.random() * maxAngle
	local halfWidth = ( self.maxX - self.minX ) / 2
	local halfHeight = ( self.maxY - self.minY ) / 2
	local maxDist = ( halfWidth ^ 2 + halfHeight ^ 2 ) ^ (0.5)
	local maxDistRoot = maxDist ^ (0.5)
	local outOfBounds = true
	local x = 0
	local y = 0
	-- find a location in bounds
	while outOfBounds do
		local temp = ( math.random() * maxDistRoot ) ^ 2
		local distance = maxDist - temp / 2
		if distance > 1000 then -- minumum distance from planet
			x = halfWidth + math.cos( angle ) * distance
			y = halfWidth + math.sin( angle ) * distance
			if x > self.minX and x < self.maxX and y > self.minY and y <= self.maxY then
				outOfBounds = false -- statistically, only a few iterations at most should occur
			end
		end
	end
	self.body:setX( x )
	self.body:setY( y )
	local xVel = math.random(-80,80)
	local yVel = math.random(-80,80)
	self.body:setLinearVelocity(xVel,yVel)
end

--[[
--When a debris is destroyed, it needs to be cleaned up.
--This function disables simulation in the game world.
--Finally, it adds the debris to the recycle bag for use later.
--WARNING: Uses global junk table.
--
--Requirement 10.1
--]]
function debris:destroy()
	--Set the debris to stop being simulated by the world.
	self.shape:setSensor( false )
	self.body:putToSleep()
	self.data.status = "DEAD"
	--Set velocity to zero and throw it off the screen.
	self.body:setLinearVelocity( 0, 0 )
	self.body:setPosition( -math.random( 10, 100 ), math.random( 10, 10000 ) )
	--Put it in the recycle bin for use later.
	junk:recycle( self )
end

--[[
--This function checks to see if a debris has exceeded a world "border".
--If it has, then it warps to the opposite border.
--This function is called by debris:update roughly once per second.
--]]
function debris:warp()
	if(self.body:getX() > self.maxX) then
		self.body:setX(self.minX)
	elseif(self.body:getX() < self.minX) then
		self.body:setX(self.maxX)
	end
	if(self.body:getY() > self.maxY) then
		self.body:setY(self.minY)
	elseif(self.body:getY() < self.minY) then
		self.body:setY(self.maxY)
	end
end

--[[
--Returns the body of the debris.
--]]
function debris:getBody()
	return self.body
end

--[[
--Returns the X coordinate of the debris.
--]]
function debris:getX()
	return self.body:getX()
end

--[[
--Returns the Y coordinate of the debris.
--]]
function debris:getY()
	return self.body:getY()
end

--[[
--Returns the type, which is "debris".
--]]
function debris:getType()
	return "debris"
end
