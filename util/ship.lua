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

-- Box2D variables
local shipBody = {}
local shipPoly = {}

-- Border awareness
local minX = {}
local maxX = {}
local screenX = {}
local minY = {}
local maxY = {}
local screenY = {}

ship = class:new(...)

--Function to initialize the ship body, shape, angle, and border awareness
function ship:init(theWorld, startX, startY, startAngle, aCoordBag)
	shipBody = love.physics.newBody(theWorld, startX, startY, 10, 1)
	shipPoly = love.physics.newPolygonShape(shipBody, 0, -15, 10, 10, -10, 10)
	shipBody:setAngle(startAngle)

	minX,maxX,screenX,minY,maxY,screenY = aCoordBag:getCoords()
end

--Simply draws the ship
function ship:draw()
	love.graphics.polygon("line", shipPoly:getPoints())
end

--A simple way to turn left
function ship:easyLeft()
	shipBody:setAngle(shipBody:getAngle() - easyTurn)
end

--An advanced way to turn left, it applies torque for angular acceleration
function ship:normalLeft()
	shipBody:applyTorque(-baseTorque)
	if shipBody:getAngularVelocity() < -maxAngleV then
		shipBody:setAngularVelocity(-maxAngleV)
	end
end

--A simple way to turn right
function ship:easyRight()
	shipBody:setAngle(shipBody:getAngle() + easyTurn)
end

--An advanced way to turn right, it applies torque for angular acceleration
function ship:normalRight()
	shipBody:applyTorque(baseTorque)
	if shipBody:getAngularVelocity() > maxAngleV then
		shipBody:setAngularVelocity(maxAngleV)
	end
end

--Applies torque counter to current angular velocity to stop rotation
function ship:stopTurn()
	if shipBody:getAngularVelocity() > 0 then
		shipBody:applyTorque(-baseTorque)
	elseif shipBody:getAngularVelocity() < 0 then
			shipBody:applyTorque(baseTorque)
	end
end

--Applies thrust to the ship, pointed in the direction the cone is facing
function ship:thrust()
	local xThrust = math.sin(shipBody:getAngle()) * baseThrust
	local yThrust = -math.cos(shipBody:getAngle()) * baseThrust
	shipBody:applyForce(xThrust,yThrust)
end

--Applies thrust to the ship, pointed in the opposite direction of the cone
function ship:reverse()
	local xThrust = math.sin(shipBody:getAngle()) * -baseThrust/2
	local yThrust = -math.cos(shipBody:getAngle()) * -baseThrust/2
	shipBody:applyForce(xThrust,yThrust)
end

--Counters thrust in all directions at a rate of 1/2 baseThrust
function ship:stopThrust()
	local xVel, yVel = shipBody:getLinearVelocity()
	local xMulti, yMulti = 0,0
	if(xVel > 0) then xMulti = -11 end
	if(xVel < 0) then xMulti = 1 end
	if(yVel > 0) then yMulti = -1 end
	if(yVel < 0) then yMulti = 1 end
	local xThrust = baseThrust/2 * xMulti
	local yThrust = baseThrust/2 * yMulti
	shipBody:applyForce(xThrust,yThrust)
end

--Uses world awareness to engage "warpdrive," causing the ship to "wrap" around
function ship:warpDrive()
	if(shipBody:getX() > maxX) then
		shipBody:setX(minX)
	end
	if(shipBody:getX() < minX) then
		shipBody:setX(maxX)
	end
	if(shipBody:getY() > maxY) then
		shipBody:setY(minY)
	end
	if(shipBody:getY() < minY) then
		shipBody:setY(maxY)
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
	return shipBody
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
