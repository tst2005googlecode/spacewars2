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

ship.lua

This class implements a generic ship.
The ship has bindings for movement and combat functions.
This ship canNOT move by itself!
	It requires a wrapper class to control its functions.
This ship is aware of the edges of the world.
	The ship:warpDrive() function will warp it from one edge to the other.
--]]

require "subclass/class.lua"

-- Movement constants
local maxLinearV -- NOT CURRENTLY IN USE!
local maxAngleV
local baseThrust
local baseTorque
local easyTurn
local turnStep
local turnAccel

-- Box2D variables
local shipBody
local shipPoly

ship = class:new(...)

-- Function to initialize the ship body, shape, angle, and border awareness
function ship:init(theWorld, startX, startY, startAngle, aCoordBag)
	self.shipBody = love.physics.newBody(theWorld, startX, startY, 10, 1)
	self.shipPoly = love.physics.newPolygonShape(self.shipBody, 0, -15, 10, 10, -10, 10)
	self.shipBody:setAngle(startAngle)

	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()

	self.maxLinearV = 30 --NOT CURRENTLY IN USE!
	self.maxAngleV = 10
	self.baseThrust = 100
	self.baseTorque = 3
	self.easyTurn = 0.005
	self.turnStep = 0
	self.turnAccel = false

	self.shipPoly:setMask(1)
end

-- Simply draws the ship
function ship:draw()
	love.graphics.polygon("line", self.shipPoly:getPoints())
end

-- A simple way to turn left
function ship:easyLeft()
	self.shipBody:setAngle(self.shipBody:getAngle() - self.easyTurn)
end

-- An advanced way to turn left, it applies torque for angular acceleration
function ship:normalLeft()
	self.shipBody:applyTorque(-self.baseTorque)
	if self.shipBody:getAngularVelocity() <= -self.maxAngleV then
		self.shipBody:setAngularVelocity(-self.maxAngleV)
	end
end

-- A complex way to turn left; apply torque for angular acceleration in steps
function ship:stepLeft()
	self.turnAccel = true
	self.turnStep = self.turnStep - 1
end

-- A simple way to turn right
function ship:easyRight()
	self.shipBody:setAngle(self.shipBody:getAngle() + self.easyTurn)
end

-- An advanced way to turn right, it applies torque for angular acceleration
function ship:normalRight()
	self.shipBody:applyTorque(self.baseTorque)
	if self.shipBody:getAngularVelocity() >= self.maxAngleV then
		self.shipBody:setAngularVelocity(self.maxAngleV)
	end
end

-- A complex way to turn right; apply torque for angular acceleration in steps
function ship:stepRight()
	self.turnAccel = true
	self.turnStep = self.turnStep + 1
end

-- In STEP mode, accelerate to set angular velocity
function ship:accelTurn()
	-- difference in current angular velocity and target angular velocity
	local curVel = self.shipBody:getAngularVelocity()
	local targetVel = self.maxAngleV * self.turnStep / 8
	local velDif = curVel - targetVel
	-- stop accelerating if close enough to target
	if math.abs( velDif ) <= self.baseTorque / 2 then
		self.shipBody:applyTorque( 0 ) -- bug in LOVE doesn't set velocity if no torque
		self.shipBody:setAngularVelocity( targetVel )
		self.turnAccel = false
	else -- otherwise, apply torque
		if velDif > 0 then
			self.shipBody:applyTorque( -self.baseTorque / 2 )
		else
			self.shipBody:applyTorque( self.baseTorque / 2 )
		end
	end
end

-- Applies torque counter to current angular velocity to stop rotation
-- Now a two-step process. If torque overcompensates, set velocity to 0.
function ship:stopTurn()
	if self.shipBody:getAngularVelocity() > 0 then
		self.shipBody:applyTorque(-self.baseTorque)
		if (self.shipBody:getAngularVelocity()) < 0 then
			self.shipBody:setAngularVelocity(0)
		end
	elseif self.shipBody:getAngularVelocity() < 0 then
		self.shipBody:applyTorque(self.baseTorque)
		if (self.shipBody:getAngularVelocity() > 0) then
			self.shipBody:setAngularVelocity(0)
		end
	end
	-- change step for step mode
	self.turnStep = math.floor( self.shipBody:getAngularVelocity() * 8 / self.maxAngleV )
end

-- Applies thrust to the ship, pointed in the direction the cone is facing
function ship:thrust()
	local xThrust = math.sin(self.shipBody:getAngle()) * self.baseThrust
	local yThrust = -math.cos(self.shipBody:getAngle()) * self.baseThrust
	self.shipBody:applyForce(xThrust,yThrust)
end

-- Applies thrust to the ship, pointed in the opposite direction of the cone
function ship:reverse()
	local xThrust = math.sin(self.shipBody:getAngle()) * -self.baseThrust/2
	local yThrust = -math.cos(self.shipBody:getAngle()) * -self.baseThrust/2
	self.shipBody:applyForce(xThrust,yThrust)
end

-- Applies thrust to the ship, pointed in the opposite direction of MOVEMENT
function ship:stopThrust()
	local xVel, yVel = self.shipBody:getLinearVelocity()
	if math.abs( xVel ) < self.baseThrust / 2 and math.abs( yVel ) < self.baseThrust / 2 then
		self.shipBody:setLinearVelocity( 0, 0 )
		return
	end
	local direction = math.atan2( -yVel, xVel ) + math.pi -- opposite current vector
	if direction > maxAngle then
		direction = direction - maxAngle
	end
	local xThrust = self.baseThrust * math.cos( direction ) / 2
	local yThrust = -self.baseThrust * math.sin( direction ) / 2

	self.shipBody:applyForce( xThrust, yThrust )
end

-- Uses world awareness to engage "warpdrive," causing the ship to "wrap" around
function ship:warpDrive()
	if(self.shipBody:getX() > self.maxX) then
		self.shipBody:setX(self.minX)
	end
	if(self.shipBody:getX() < self.minX) then
		self.shipBody:setX(self.maxX)
	end
	if(self.shipBody:getY() > self.maxY) then
		self.shipBody:setY(self.minY)
	end
	if(self.shipBody:getY() < self.minY) then
		self.shipBody:setY(self.maxY)
	end
end

-- Fires a laser
function ship:laser()
end

-- Fires a missile
function ship:missile()
end

-- Fires a tractor beam
function ship:tractor()
end

-- Returns the ship body for use by other classes, such as a camera!
function ship:getBody()
	return self.shipBody
end

function ship:getTurnAccel()
	return self.turnAccel
end

function ship:getX()
	return self.shipBody:getX()
end

function ship:getY()
	return self.shipBody:getY()
end

function ship:getPoints()
	return self.shipPoly:getPoints()
end

-- Function to check maximum linear velocity.
-- CURRENTLY NOT IN USE!
function checkMaxLinearVelocity(xVelocity,yVelocity)
	if(xVelocity > maxLinearV) then
		xVelocity = maxLinearV
	end
	if(xVelocity < -maxLinearV) then
		xVelocity = -maxLinearV
	end
	if(yVelocity > maxLinearV) then
		yVelocity = maxLinearV
	end
	if(yVelocity < -maxLinearV) then
		yVelocity = -maxLinearV
	end
	return xVelocity,yVelocity
end
