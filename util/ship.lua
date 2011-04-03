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
The ship has functions for movement and combat.
This ship canNOT move by itself!
	It requires a controller (player or AI) object to command its functions.
This ship is aware of the edges of the world.
	The ship:warpDrive() function will warp it from one edge to the other.
--]]

require "util/bodyObject.lua"
require "util/functions.lua"
require "util/missile.lua"

-- Movement constants
local maxLinearV -- NOT CURRENTLY IN USE!
local maxAngleV
local baseThrust
local baseTorque
local easyTurn
local turnStep
local turnAccel

-- ship attributes
local shipType
local color
local controller
local data -- contains ship systems, state, etc

ship = bodyObject:new(...)

-- Function to constructialize the ship body, shape, angle, and border awareness
function ship:construct( theWorld, controlledBy, aCoordBag, shipConfig )
	self.controller = controlledBy -- player or AI
	self:constructBody( theWorld, shipConfig.startX, shipConfig.startY, shipConfig.mass, shipConfig.mass * ( 25 * 10 ) * ( 100000 ^ 2 ) / 6 )
	self.shipType = shipConfig.shipType

	-- initial angle is 0 (right), so point ship to the right
	self.shipPoly = love.physics.newPolygonShape(self.body, 15, 0, -10, 10, -10, -10, -12, 0)
	self.body:setAngle( shipConfig.startAngle )

	--coordinate variables
	self.coordBag = aCoordBag
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()

	self.shipConfig = shipConfig

	-- these need to be set from shipConfig
	self.maxLinearV = 30 --NOT CURRENTLY IN USE!
	self.maxAngleV = 0.1 * timeScale
	self.baseThrust = shipConfig.mass * 400
	self.baseTorque = shipConfig.mass ^ 3 * 10000
	self.easyTurn = 0.005 / timeScale

	-- state controls for step turning
	self.turnStep = 0
	self.turnAccel = false

--	self.shipPoly:setMask(1)
	self.shipPoly:setSensor(true)
	self.color = shipConfig.color

	--store the world for laser and missile creation
	self.world = theWorld

	--ship data, has a default of SHIP for self.data.status which should be overwritten
	self.data = {}
	self.data.objectType = types.ship
	self.data.owner = self.controller
	self.data.armor = 12500
	self.shipPoly:setData( self )
	self.data.missiles = {}
	self.data.newMissiles = {}
	self.data.missileBank = 10
end

function ship:draw()
	love.graphics.setColor( unpack( self.color ) )
	love.graphics.polygon( "line", self.shipPoly:getPoints() )
end

-- checks every dt seconds for commands, and execute the appropriate function
function ship:update( dt )
	local commands = self.controller:updateControls( self.data )
	if self.data.status == "DEAD" then
		if commands[1] == "respawn" then
			self:respawn()
		end
		return
	end
	-- checking for dead missiles is always a vaild operation
	for i, aMissile in ipairs( self.data.missiles ) do
		if not aMissile.isActive then
			table.remove( self.data.missiles, i )
			self.data.missileBank = self.data.missileBank + 1
		end
	end
	for i, command in ipairs( commands ) do
		if command == "stop" then
			self:stopThrust( dt )
		elseif command == "thrust" then
			self:thrust()
		elseif command == "reverse" then
			self:reverse()
		elseif command == "stopRotation" then
			self:stopTurn()
		elseif command == "easyLeft" then
			self:easyLeft()
		elseif command == "normalLeft" then
			self:normalLeft()
		elseif command == "stepLeft" then
			self:stepLeft()
		elseif command == "easyRight" then
			self:easyRight()
		elseif command == "normalRight" then
			self:normalRight()
		elseif command == "stepRight" then
			self:stepRight()
		elseif command == "orbit" then
			self:orbit( dt )
		elseif command == "launchMissile" then
			self:launchMissile()
		elseif command == "engageLaser" then
			self:engageLaser()
		end
	end
	-- accelerate turn if turning
	if self.turnAccel then
		self:accelTurn()
	end
	-- check boundary and activate the ship's warpdrive if needed.
	self:warpDrive()
end

-- A simple way to turn left
function ship:easyLeft()
	self.body:setAngle( self.body:getAngle() - self.easyTurn * timeScale )
end

-- An advanced way to turn left, it applies torque for angular acceleration
function ship:normalLeft()
	self.body:applyTorque( -self.baseTorque * forceScale )
	--[[if self.body:getAngularVelocity() <= -self.maxAngleV then
		self.body:setAngularVelocity(-self.maxAngleV)
	end--]]
end

-- A complex way to turn left; apply torque for angular acceleration in steps
function ship:stepLeft()
	self.turnAccel = true
	self.turnStep = self.turnStep - 1
end

-- A simple way to turn right
function ship:easyRight()
	self.body:setAngle( self.body:getAngle() + self.easyTurn * timeScale )
end

-- An advanced way to turn right, it applies torque for angular acceleration
function ship:normalRight()
	self.body:applyTorque( self.baseTorque * forceScale )
	--[[if self.body:getAngularVelocity() >= self.maxAngleV then
		self.body:setAngularVelocity(self.maxAngleV)
	end--]]
end

-- A complex way to turn right; apply torque for angular acceleration in steps
function ship:stepRight()
	self.turnAccel = true
	self.turnStep = self.turnStep + 1
end

-- In STEP mode, accelerate to set angular velocity
function ship:accelTurn()
	-- difference in current angular velocity and target angular velocity
	local curVel = self.body:getAngularVelocity()
	local targetVel = self.maxAngleV * self.turnStep / 8
	local velDif = curVel - targetVel
	-- stop accelerating if close enough to target
	if math.abs( velDif ) <= self.baseTorque / 2 then
		self.body:applyTorque( 0 ) -- bug in LOVE doesn't set velocity if no torque
		self.body:setAngularVelocity( targetVel )
		self.turnAccel = false
	else -- otherwise, apply torque
		if velDif > 0 then
			self.body:applyTorque( -self.baseTorque * forceScale / 2 )
		else
			self.body:applyTorque( self.baseTorque * forceScale / 2 )
		end
	end
end

-- Applies torque counter to current angular velocity to stop rotation
-- Now a two-step process. If torque overcompensates, set velocity to 0.
function ship:stopTurn()
	if self.body:getAngularVelocity() > 0 then
		self.body:applyTorque( -self.baseTorque * forceScale )
		if (self.body:getAngularVelocity()) < 0 then
			self.body:setAngularVelocity(0)
		end
	elseif self.body:getAngularVelocity() < 0 then
		self.body:applyTorque( self.baseTorque * forceScale )
		if (self.body:getAngularVelocity() > 0) then
			self.body:setAngularVelocity(0)
		end
	end
	-- change step for step mode
	self.turnStep = math.floor( self.body:getAngularVelocity() * 8 / self.maxAngleV )
end

-- Applies thrust to the ship, pointed in the direction the cone is facing
function ship:thrust()
	local scaledThrust = self.baseThrust * forceScale
	local angle = self.body:getAngle()
	local xThrust = math.cos( angle ) * scaledThrust
	local yThrust = math.sin( angle ) * scaledThrust
	self.body:applyForce( xThrust, yThrust )
end

-- Applies thrust to the ship, pointed in the opposite direction of the cone
function ship:reverse()
	local halfThrustScaled = self.baseThrust * forceScale / 2
	local angle = self.body:getAngle()
	local xThrust = math.cos( angle ) * halfThrustScaled
	local yThrust = math.sin( angle ) * halfThrustScaled
	self.body:applyForce( -xThrust, -yThrust  )
end

-- Applies thrust to the ship, pointed in the opposite direction of MOVEMENT
function ship:stopThrust( dt )
	local xVel, yVel = self.body:getLinearVelocity()
	local halfThrustScaled = self.baseThrust * forceScale / 2
	local minVel = halfThrustScaled * dt / self.body:getMass()
	if math.abs( xVel ) < minVel and math.abs( yVel ) < minVel then
		self.body:setLinearVelocity( 0, 0 )
		return
	end
	local direction = math.atan2( yVel, xVel ) + math.pi -- opposite current vector
	if direction > maxAngle then
		direction = direction - maxAngle
	end
	local xThrust = halfThrustScaled * math.cos( direction )
	local yThrust = halfThrustScaled * math.sin( direction )

	self.body:applyForce( xThrust, yThrust )
end

-- Applies thrust to the ship to orbit the nearest planet
function ship:orbit( dt )
	local aSolarMass = solarMasses.objects[ 1 ] -- get nearest mass later
	local difX = aSolarMass.body:getX() - self.body:getX()
	local difY = aSolarMass.body:getY() - self.body:getY()
	local dist = hypotenuse( difX, difY )

	-- Is the ship within range to orbit?  Need to know the max ship width ...
	-- 15 pixels is approximate for now, for half of max width
	if dist > aSolarMass.radius + 15 and dist < aSolarMass.radius * 8 then
		local dir = math.atan2( difY, difX )
		-- orbit velocity in pixels / second
		local scaledOrbitVel =
			( ( ( aSolarMass.body:getMass() ^ 2 ) * gravity /
				( ( self.body:getMass() + aSolarMass.body:getMass() ) *
				  dist * distanceScale )
			  ) ^ ( 1 / 2 )
			) * timeScale / distanceScale -- required velocity to orbit at current radius
		local orbitAngle = dir - quarterCircle -- perpendicular to angle to mass
		if orbitAngle < 0 then -- make it positive
			orbitAngle = maxAngle + orbitAngle
		end
		local velX, velY = self.body:getLinearVelocity()
		local orbVelX = math.cos( orbitAngle ) * scaledOrbitVel -- X component
		local orbVelY = math.sin( orbitAngle ) * scaledOrbitVel -- Y component
		local velDifX = orbVelX - velX -- X component of force direction needed
		local velDifY = orbVelY - velY -- Y component of force direction needed
		local forceAngle = math.atan2( velDifY, velDifX )
		lastAngle = scaledOrbitVel
		local forceVel = hypotenuse( velDifX, velDifY ) -- scalar in force direction

		-- apply 1/2 thrust in forceAngle direction ... use less force if needed
		local f = self.baseThrust * forceScale / 4 -- scaled force to apply
		-- compare velocity
		if forceVel < f * timeScale * dt / self.body:getMass() then
			f = forceVel * timeScale * dt * self.body:getMass()
		end
		self.body:applyForce( f * math.cos( forceAngle ), f * math.sin( forceAngle ) )
	end
end

-- Uses world awareness to engage "warpdrive," causing the ship to "wrap" around
function ship:warpDrive()
	if(self.body:getX() > self.maxX) then
		self.body:setX(self.minX)
	end
	if(self.body:getX() < self.minX) then
		self.body:setX(self.maxX)
	end
	if(self.body:getY() > self.maxY) then
		self.body:setY(self.minY)
	end
	if(self.body:getY() < self.minY) then
		self.body:setY(self.maxY)
	end
end

function ship:destroy()
	--self:deactivate()
	self.data.status = "DEAD"
	self.controller.state.respawn = true
end

-- engage laser
function ship:engageLaser()
end

-- launch a missile
function ship:launchMissile( target ) -- target TODO
	if self.data.missileBank > 0 then
		local angle = self.body:getAngle()
		local x = self.body:getX() + math.cos( angle ) * 25
		local y = self.body:getY() + math.sin( angle ) * 25
		local xVel, yVel = self.body:getLinearVelocity()
		local aMissile = missiles:getNew( self.world, x, y, angle, self.coordBag, self.shipConfig, xVel, yVel )
		aMissile:setOwner( self.controller )
		self.data.missiles[ #self.data.missiles + 1 ] = aMissile
		self.data.newMissiles[ #self.data.newMissiles + 1 ] = aMissile
		self.data.missileBank = self.data.missileBank - 1
		game:addActive( aMissile )
		print ( "launchedMissile" )
	end
end

-- the player's new missiles
function ship:getNewMissiles()
	local returnMissiles = {}
	returnMissiles = self.data.newMissiles
	self.data.newMissiles = nil
	self.data.newMissiles = {}
	return returnMissiles
end

-- remaining missiles
function ship:getMissileBank()
	return self.data.missileBank
end

-- engage a tractor beam
function ship:engageTractor()
end

-- Respawn the ship in a random quadrant within 800 pixels of the borders, pointed in a random angle
function ship:respawn()
	self.data.status = "ACTIVE"
	x = math.random(0,800)
	y = math.random(0,800)
	xSide = math.random(0,1)
	ySide = math.random(0,1)
	if xSide == 1 then
		x = self.maxX - x
	end
	if ySide == 1 then
		y = self.maxY - y
	end
	angle = math.random() * maxAngle
	self.body:setX(x)
	self.body:setY(y)
	self.body:setAngle(angle)
	self.body:setLinearVelocity(0,0)
	self.body:setAngularVelocity(0)
end

--[[] Returns the ship body for use by other classes, such as a camera!
function ship:getBody()
	return self.body
end--]]

function ship:getTurnAccel()
	return self.turnAccel
end

-- Get the body's X position
function ship:getX()
	return self.body:getX()
end

-- Get the body's Y position
function ship:getY()
	return self.body:getY()
end

-- Get the points that make up the ship polygon
function ship:getPoints()
	return self.shipPoly:getPoints()
end

-- Get the ship's current status
function ship:getStatus()
	return self.data.status
end

-- Set the ship's current status
function ship:setStatus(stat)
	self.data.status = stat
end

-- the type of ship this is
function ship:getType()
	return self.shipType
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
