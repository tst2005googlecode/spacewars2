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

missile.lua

This class implements a missile object.
Missiles are somewhat oblong in shape.
Missiles spawn at the center of the ship.
	Missiles immediately turn and pursue their chosen target.
	Missiles thrust until they run out of fuel.
	Upon fuel exhaustion, missiles coast until the killswitch exhausts.
	Finally, the missile self-destructs.
Missiles are aware of the borders of the world.
	Upon reaching a border, the missile self-destructs.
Missiles have 500 armor that must be depleted by lasers before destruction.

WARNING: Uses global timeScale variable from game.lua
WARNING: Uses global missile table from game.lua
--]]

require "subclass/class.lua"
require "util/bodyObject.lua"
require "util/functions.lua"

local color
local mass = 10
local owner
local lastTargetAngle
local lastTargetDist
local lastHeading
local lastX
local lastY
local turnDelay

missile = bodyObject:new(...)

--[[
--Construct a missile if a recycled instance does not exist.
--Sets border awareness, constructs a body/shape, and sets object data.
--Ends by calling the init function.
--
--Requirement 9.1
--]]
function missile:construct(aWorld, x, y, startAngle, aCoordBag, shipConfig, xVel, yVel)
	--Construct a missile body.
	self:constructBody(aWorld, x, y, mass, mass * ( 25 * 10 ) * ( 100000 ^ 2 ) / 6)
	--self.missilePoly = love.physics.newPolygonShape(self.body, 12, 0, 6, -1, -6, -1, -8, 0, -6, 1, 6, 1)
	self.missilePoly = love.physics.newPolygonShape(self.body, 12, 0, 2, 4, -4, 4, -8, 0, -4, -4, 2, -4)
	--Set world awareness.
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
	--Set the missile's data.
	self.data = {}
	self.objectType = types.missile
	self.mass = mass
	self.missilePoly:setData( self )

	self:init( aWorld, x, y, startAngle, aCoordBag, shipConfig, xVel, yVel )
end

--[[
--Initializes a newly constructed or recycles instance of missile.
--Sets the velocity, angle, and spawn position of the missile.
--Sets the missile up for use in the game engine.
--WARNING: Uses global timeScale variable.
--
--Requirement 9.1
--]]
function missile:init(aWorld, x, y, startAngle, aCoordBag, shipConfig, xVel, yVel)
	--Sets the missile's position and velocity.
	self.body:setAngle(startAngle)
	self.body:setLinearVelocity(xVel,yVel)
	self.body:setPosition( x, y )
	--Setup the missile for simulation in the world.
	self.body:wakeUp()
	self.missilePoly:setSensor( true )

	--Set the thrust and torque of the missile based on mass.
	self.baseThrust = self.mass * 1000
--	self.baseTorque = self.mass ^ 3 * 10000
	self.easyTurn = 0.001 / timeScale

	--Set the color of the missile, and reset its fuel, killswitch, and target.
	self.color = shipConfig.color
	self.fuel = 6000/timeScale
	self.killswitch = 6000/timeScale
	self.target = {}

	--Set the owner of the missile for collision detection.
	self.data.owner = ""
	self.data.status = ""

	--Set the missiles armor and damage values.
	self.data.armor = 500
	self.data.damage = 1000

	-- set initial "previous" values
	self.lastTargetAngle = startAngle
	self.lastHeading = startAngle
	
	self.turnDelay = 0
end

--[[
--This sets the target of the missile to the specified body.
--The missile should home in on the target while fuel is available.
--
--Requirement 9.1
--]]
function missile:setTarget(aTarget)
	self.target = aTarget
	-- set target last variables
	self.lastX = self.body:getX()
	self.lastY = self.body:getX()
	self.lastTargetAngle = missile:getOptimalInterceptAngle( self, aTarget )
	-- pointAngle( self.body:getX(), self.body:getY(), aBody:getX(), aBody:getY() )
	self.lastTargetDist = pointDistance( self.lastX, self.lastY, aTarget:getX(), aTarget:getY() )
	self.body:setAngle( self.lastTargetAngle )
end

--[[
-- This finds the optimal angle to head to intercept the target ... assumes target 
-- does not accelerate; missile tracking will compensate for target accelaration
--
-- Requirement 9.1
--]]
function missile:getOptimalInterceptAngle( aMissile, aTarget )
	local accel = aMissile.baseThrust * forceScale / aMissile.body:getMass() -- a = F / m
	local mVelX, mVelY = aMissile.body:getLinearVelocity() -- missile velocity components
	local tVelX, tVelY = aTarget.body:getLinearVelocity()     -- target velocity components
	-- determine relative velocity and angle for target ... missile will be 0
	local relVelX = mVelX + tVelX
	local relVelY = mVelY + tVelY
	local relVel = hypotenuse( relVelX, relVelY )
	local relTargetHeading = math.atan2( relVelY, relVelX )
	local mX0, mY0 = aMissile.body:getPosition() -- missile start position
	local tX, tY = aTarget.body:getPosition() -- projected target position
	-- distance to target
	local dist = pointDistance( mX0, mY0, tX, tY )
	local tDist = dist
	local mDist = 0
	local i = 0
	
	-- iteratively search for optimum distance to travel
	local scale = worldScale / 2 -- not sure why, but this "fixes" error
	repeat
		i = i + 1
		mDist = accel * ( i * i ) * scale
		tX = tX + relVelX
		tY = tY + relVelY
		tDist = pointDistance( mX0, mY0, tX, tY )
	until mDist > tDist or mDist > 16384
	
	return pointAngle( mX0, mY0, tX, tY ) -- angle to estimated location
end

--[[
--Draws the missile on the screen.
--]]
function missile:draw()
	if self.isActive then
		love.graphics.setColor( unpack( self.color ) )
		love.graphics.polygon("fill", self.missilePoly:getPoints())
	end
end

--[[
--Updates the missile in the world.
--Missiles will exhaust dt milliseconds of fuel on every update.
--Once fuel is exhausted, it exhausts the killswitch instead.
--Upon total killswitch exhaustion or exceeding a boundary, it self-destructs.
--
--Requirement 9.1
--]]
function missile:update(dt)
	--[[if(self.data.status == "DEAD") then
		--Hold down timer to make sure EVERYTHING stops referencing it
		if(self.holdTime > 0) then
			self.holdTime = self.holdTime - 1
		else
			self:destroy()
		end
		return
	end--]]
	--Smart missiles can't track over a border, so all missiles self-destruct.
	if(self:offedge() == true) then
		self:destroy()
	--Missile has fuel to thrust.
	elseif(self.fuel > 0) then
		self:thrust()
		self:turn( dt )
		self.fuel = self.fuel - dt
	--Missile drifts until killswitch time elapses.
	elseif(self.killswitch > 0) then
		self.killswitch = self.killswitch - dt
	else --Killswitch exhaustion means the missile self-destructs.
		self:destroy()
	end
end

--[[
--When a missile is destroyed, it needs to be cleaned up.
--This function disables simulation in the game world.
--Finally, it adds the missile to the recycle bag for use later.
--WARNING: Uses global missile table.
--
--Requirement 9.2
--]]
function missile:destroy()
	--Set the missile to stop simulation in the world.
	self.missilePoly:setSensor( false )
	self.body:putToSleep()
	self.data.status = "DEAD"
	--Set velocity to zero and throw it off the screen.
	self.body:setLinearVelocity( 0, 0 )
	self.body:setPosition( -math.random( 10, 100 ), math.random( 10, 10000 ) )
	--Put the missile in the recycle bin.
	missiles:recycle( self )
end

--[[
--Executed on an update cycle if fuel still exists.
--Causes the missile to accelerate in the direction it's pointed by applying force.
--
--Requirement 9.1
--]]
function missile:thrust()
	local scaledThrust = self.baseThrust * forceScale
	local angle = self.body:getAngle()
	--Calculate what portion of thrust to apply on the X and Y axis.
	local xThrust = math.cos( angle ) * scaledThrust
	local yThrust = math.sin( angle ) * scaledThrust
	self.body:applyForce( xThrust, yThrust )
end

--[[
-- use proportional navigation to determin missile heading to target
-- course correction will be applies more frequently as missile gets closer to target
-- Requirement 9.1
--]]
function missile:turn( dt )
	if (self.target ~= {}) then
		self.turnDelay = self.turnDelay + dt * timeScale
		if self.turnDelay > 1 then -- only change heading every second (virtual)
			local tX0, tY0 = self.target.body:getPosition()
			local mX0, mY0 = self.body:getPosition()
			-- current distant to target
			local tDist = pointDistance( mX0, mY0, tX0, tY0 )
			local turnRate = tDist / 100 -- more frequent turns closer to target
			if self.turnDelay < turnRate then
				return -- so we don't degrade performance
			end
			self.turnDelay = self.turnDelay - turnRate
			-- current angle to target
			local tAngle = pointAngle( mX0, mY0, tX0, tY0 )
			-- difference in distance to target
			local dDist = self.lastTargetDist - tDist
			-- difference in angle to target
			local dAngle = self.lastTargetAngle - tAngle
			if math.abs( dAngle ) + tAngle > maxAngle then -- normalize angle difference
				if dAngle < 0 then
					dAngle = dAngle + maxAngle
				else
					dAngle = dAngle - maxAngle
				end
			end
			local mVel = hypotenuse( self.body:getLinearVelocity() )
			-- calculate acceleration required normal to angle to target
			 -- N = 4 ... already scaled by time and distance
			local accelN = 4 * mVel * ( dAngle / dDist ) / ( dt / dDist )
			local accelH = self.baseThrust * forceScale / self.body:getMass()
			self.lastX = self.body:getX()
			self.lastY = self.body:getY()
			-- calculate sin of angle made by components opposite over hypotenuse
			local sinO = accelN / ( accelH * mVel ) -- scale by missile velocity (not sure why)
			-- sin shouldn't go beyond -1, 1, but check to make sure
			if sinO > 1 then
				sinO = 1
			end
			if sinO < -1 then
				sinO = -1
			end
			local cosO = ( 1 - sinO ^ 2 ) ^ 0.5
			local angleDiff = math.atan2( sinO, cosO ) -- proportional angle difference
			-- apply proportional navigation
			-- not sure why I wouldn't add angle difference ... adding makes missiles 
			--   not track correctly
			--if dAngle < 0 then
				self.lastHeading = tAngle - angleDiff
			--[[else
				self.lastHeading = tAngle + angleDiff
			end--]]
			self.lastTargetAngle = tAngle
			self.lastTargetDist = tDist
			
			self.body:setAngle( self.lastHeading )
		end
	end
end

--[[
--Checks to see if the missile has exceeded a world boundary.
--If so, then it returns true, so the update method destroys the missile.
--Otherwise, it returns false, which will cause nothing to happen.
--
--Requirement 9.1
--]]
function missile:offedge()
	if(self.body:getX() > self.maxX) then
		return true
	elseif(self.body:getX() < self.minX) then
		return true
	end
	if(self.body:getY() > self.maxY) then
		return true
	elseif(self.body:getY() < self.minY) then
		return true
	end
	return false
end

--[[
--Get the status of the missile.
--]]
function missile:getStatus()
	return self.data.status
end

--[[
--Set the status of the missile.
--]]
function missile:setStatus(stat)
	self.data.status = stat
end

--[[
--Get the owner of the missile.
--]]
function missile:getOwner()
	return self.data.owner
end

--[[
--Set the owner of the missile.
--]]
function missile:setOwner(own)
	self.data.owner = own
end

--[[
--Get the X coordinate of the missile.
--]]
function missile:getX()
	return self.body:getX()
end

--[[
--Get the Y coordinate of the missile.
--]]
function missile:getY()
	return self.body:getY()
end

--[[
--Get the type of the missile, which is "missile".
--]]
function missile:getType()
	return "missile"
end
