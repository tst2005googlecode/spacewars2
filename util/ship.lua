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
local maxLinearV = 30 --NOT CURRENTLY IN USE!
local maxAngleV = 10
local baseThrust = 100
local baseTorque = 3
local easyTurn = 0.005

ship = class:new(...)

--Function to initialize the ship body, shape, angle, and border awareness
function ship:init(theWorld, startX, startY, startAngle, aCoordBag)
	self.shipBody = love.physics.newBody(theWorld, startX, startY, 10, 1)
	self.shipPoly = love.physics.newPolygonShape(self.shipBody, 0, -15, 10, 10, -10, 10)
	self.shipBody:setAngle(startAngle)

	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
end

--Simply draws the ship
function ship:draw()
	love.graphics.polygon("line", self.shipPoly:getPoints())
end

--A simple way to turn left
function ship:easyLeft()
	self.shipBody:setAngle(self.shipBody:getAngle() - easyTurn)
end

--An advanced way to turn left, it applies torque for angular acceleration
function ship:normalLeft()
	self.shipBody:applyTorque(-baseTorque)
	if self.shipBody:getAngularVelocity() < -maxAngleV then
		self.shipBody:setAngularVelocity(-maxAngleV)
	end
end

--A simple way to turn right
function ship:easyRight()
	self.shipBody:setAngle(self.shipBody:getAngle() + easyTurn)
end

--An advanced way to turn right, it applies torque for angular acceleration
function ship:normalRight()
	self.shipBody:applyTorque(baseTorque)
	if self.shipBody:getAngularVelocity() > maxAngleV then
		self.shipBody:setAngularVelocity(maxAngleV)
	end
end

--Applies torque counter to current angular velocity to stop rotation
--Now a two-step process. If torque overcompensates, set velocity to 0.
function ship:stopTurn()
	if self.shipBody:getAngularVelocity() > 0 then
		self.shipBody:applyTorque(-baseTorque)
		if (self.shipBody:getAngularVelocity()) < 0 then
			self.shipBody:setAngularVelocity(0)
		end
	elseif self.shipBody:getAngularVelocity() < 0 then
			self.shipBody:applyTorque(baseTorque)
		if (self.shipBody:getAngularVelocity() > 0) then
			self.shipBody:setAngularVelocity(0)
		end
	end
end

--Applies thrust to the ship, pointed in the direction the cone is facing
function ship:thrust()
	local xThrust = math.sin(self.shipBody:getAngle()) * baseThrust
	local yThrust = -math.cos(self.shipBody:getAngle()) * baseThrust
	self.shipBody:applyForce(xThrust,yThrust)
end

--Applies thrust to the ship, pointed in the opposite direction of the cone
function ship:reverse()
	local xThrust = math.sin(self.shipBody:getAngle()) * -baseThrust/2
	local yThrust = -math.cos(self.shipBody:getAngle()) * -baseThrust/2
	self.shipBody:applyForce(xThrust,yThrust)
end

--Applies thrust to the ship, pointed in the opposite direction of MOVEMENT
function ship:stopThrust()
	local xVel, yVel = self.shipBody:getLinearVelocity()
	if math.abs( xVel ) < baseThrust / 2 and math.abs( yVel ) < baseThrust / 2 then
		self.shipBody:setLinearVelocity( 0, 0 )
		return
	end
	local direction = math.atan2( -yVel, xVel ) + math.pi -- opposite current vector
	if direction > maxAngle then
		direction = direction - maxAngle
	end
	local xThrust = baseThrust * math.cos( direction ) / 2
	local yThrust = -baseThrust * math.sin( direction ) / 2

	self.shipBody:applyForce( xThrust, yThrust )
end

--Uses world awareness to engage "warpdrive," causing the ship to "wrap" around
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

--Fires a laser
function ship:laser()
end

--Fires a missile
function ship:missile()
end

--Fires a tractor beam
function ship:tractor()
end

--Returns the ship body for use by other classes, such as a camera!
function ship:getBody()
	return self.shipBody
end

--Function to check maximum linear velocity.
--CURRENTLY NOT IN USE!
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
