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

--[[
--Constructs and initializes a ship object.
--Initializes the body, shape, angle, and border awareness.
--Also initializes control constants, armor, and weapon capacity.
--]]
function ship:construct( theWorld, controlledBy, aCoordBag, shipConfig )
	--Set the controller, and construct the ship.
	self.controller = controlledBy
	self:constructBody( theWorld, shipConfig.startX, shipConfig.startY, shipConfig.mass, shipConfig.mass * ( 25 * 10 ) * ( 100000 ^ 2 ) / 6 )
	self.shipType = shipConfig.shipType

	--Set the initial angle for the ship.
	self.shipPoly = love.physics.newPolygonShape(self.body, 15, 0, -10, -10, -15, 0, -10, 10)
	self.body:setAngle( shipConfig.startAngle )

	--Initialize world awareness and store configuration data.
	self.coordBag = aCoordBag
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
	self.shipConfig = shipConfig

	--Initialize propulsion constants.
	self.maxLinearV = 30 --NOT CURRENTLY IN USE!
	self.maxAngleV = 0.1 * timeScale --NOT CURRENTLY IN USE!
	self.baseThrust = shipConfig.mass * 500
	self.baseTorque = shipConfig.mass ^ 3 * 50000
	self.easyTurn = 0.0000005 * timeScale

	--State controls for step turning
	self.turnStep = 0
	self.turnAccel = false

	--Set the ship for simulation within the world.
	self.shipPoly:setSensor(true)
	self.shipPoly:setData( self )
	self.color = shipConfig.color

	--Store a world reference for laser and missile creation
	self.world = theWorld

	--Set the ship's data, including armor and weapon capacities.
	self.data = {}
	self.objectType = types.ship
	self.data.owner = self.controller

	self.data.armor = 2000
	self.data.missiles = {}
	self.data.newMissiles = {}
	self.data.missileBank = 10
	self.data.laserEngaged = false
	self.data.minimumLaserCharge = 1
	self.data.laserCharge = 1
	self.data.laserUse = 1
end

--[[
--Draws the ship on the screen with the stored color.
--]]
function ship:draw()
	--If a ship is destroyed, then it shouldn't be drawn.
	--Used for the player's ship.
	if(not self.controller.state.respawn) then
		love.graphics.setColor( unpack( self.color ) )
		love.graphics.polygon( "fill", self.shipPoly:getPoints() )
	end
end

--[[
--Updates the ship every dt seconds.
--Polls the controller on every iteration for commands.
--If possible, executes the commands requested by the controller.
--]]
-- checks every dt seconds for commands, and execute the appropriate function
function ship:update( dt )
	--Get commands from controller
	local commands = self.controller:updateControls( self.data, dt )
	--Check for respawn
	if self.data.status == "DEAD" then
		if commands[1] == "respawn" then
			self:respawn()
		end
		return
	end
	--Charge laser
	self.data.laserCharge = 1
	--Checking for dead missiles to replenish reserves.
	for i, aMissile in ipairs( self.data.missiles ) do
		if not aMissile.isActive then
			table.remove( self.data.missiles, i )
			self.data.missileBank = self.data.missileBank + 1
		end
	end
	--Execute all commands from controller
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
			self:launchMissile( love.mouse.getX(), love.mouse.getY() )
		elseif command == "engageLaser" then
			self.data.laserEngaged = true
		elseif command == "disengageLaser" then
			self.data.laserEngaged = false
		end
	end
	--Start/continue laser beam
	if self.data.laserEngaged then
		self:engageLaser( dt, love.mouse.getX(), love.mouse.getY() )
	end
	--Sccelerate turn if using STEP mode.
	if self.turnAccel then
		self:accelTurn()
	end
	--Check boundary and activate the ship's warp drive if needed.
	self:warpDrive()
end

--[[
--A simple, constant turn to the left.
--]]
function ship:easyLeft()
	self.body:setAngle( self.body:getAngle() - self.easyTurn * timeScale )
end

--[[
--An advanced, torque accelerated turn to the left.
--]]
function ship:normalLeft()
	self.body:applyTorque( -self.baseTorque * forceScale )
	--[[if self.body:getAngularVelocity() <= -self.maxAngleV then
		self.body:setAngularVelocity(-self.maxAngleV)
	end--]]
end

--[[
--An advanced turn to the left that causes the ship to continue rotating at a certain speed.
--]]
function ship:stepLeft()
	self.turnAccel = true
	self.turnStep = self.turnStep - 1
end

--[[
--A simple, constant turn to the right.
--]]
function ship:easyRight()
	self.body:setAngle( self.body:getAngle() + self.easyTurn * timeScale )
end

--[[
--An advanced, torque accelerated turn to the right.
--]]
function ship:normalRight()
	self.body:applyTorque( self.baseTorque * forceScale )
	--[[if self.body:getAngularVelocity() >= self.maxAngleV then
		self.body:setAngularVelocity(self.maxAngleV)
	end--]]
end

--[[
--An advanced turn to the right that causes the ship to continue rotating at a certain speed.
--]]
function ship:stepRight()
	self.turnAccel = true
	self.turnStep = self.turnStep + 1
end

--[[
--Used in STEP mode to accelerate the constant turn rate.
--]]
function ship:accelTurn()
	--Find difference in current angular velocity and target angular velocity
	local curVel = self.body:getAngularVelocity()
	local targetVel = self.maxAngleV * self.turnStep / 8
	local velDif = curVel - targetVel
	if math.abs( velDif ) <= self.baseTorque / 2 then
		--Stop accelerating if close enough to target
		self.body:applyTorque( 0 ) --Bug in LOVE doesn't set velocity if no torque
		self.body:setAngularVelocity( targetVel )
		self.turnAccel = false
	else
		--Otherwise, apply torque
		if velDif > 0 then
			self.body:applyTorque( -self.baseTorque * forceScale / 2 )
		else
			self.body:applyTorque( self.baseTorque * forceScale / 2 )
		end
	end
end

--[[
--Applies torque counter to current angular velocity to stop rotation
--If torque overcompensates, set angular velocity to 0.
--]]
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
	--Change step for step mode
	self.turnStep = math.floor( self.body:getAngularVelocity() * 8 / self.maxAngleV )
end

--[[
--Applies thrust to the ship, pointed in the direction the cone is facing
--]]
function ship:thrust()
	local scaledThrust = self.baseThrust * forceScale
	local angle = self.body:getAngle()
	--Apply the proper amount of thrust in the X and Y directions.
	local xThrust = math.cos( angle ) * scaledThrust
	local yThrust = math.sin( angle ) * scaledThrust
	self.body:applyForce( xThrust, yThrust )
end

--[[
--Applies thrust to the ship, pointed in the opposite direction of the cone
--Reversing occurs at 1/2 normal thrust.
--]]
function ship:reverse()
	local halfThrustScaled = self.baseThrust * forceScale / 2
	local angle = self.body:getAngle()
	--Apply the proper amount of thrust in the X and Y directions.
	local xThrust = math.cos( angle ) * halfThrustScaled
	local yThrust = math.sin( angle ) * halfThrustScaled
	self.body:applyForce( -xThrust, -yThrust  )
end

--[[
--Applies thrust to the ship, pointed in the opposite direction of MOVEMENT
--All stop occurs at 1/2 normal thrust.
--]]
function ship:stopThrust( dt )
	local xVel, yVel = self.body:getLinearVelocity()
	local halfThrustScaled = self.baseThrust * forceScale / 2
	local minVel = halfThrustScaled * dt / self.body:getMass()
	if math.abs( xVel ) < minVel and math.abs( yVel ) < minVel then
		--Snap linear velocity to 0 and return
		self.body:setLinearVelocity( 0, 0 )
		return
	end
	--Find the direction opposite the current vector.
	local direction = math.atan2( yVel, xVel ) + math.pi
	if direction > maxAngle then
		--Roll the angle past 2*pi.
		direction = direction - maxAngle
	end
	--Apply the proper amount of thrust in the X and Y directions.
	local xThrust = halfThrustScaled * math.cos( direction )
	local yThrust = halfThrustScaled * math.sin( direction )

	self.body:applyForce( xThrust, yThrust )
end

--[[
--Applies thrust to the ship to orbit the nearest planet
--WARNING: Uses the global solarMasses table.
--]]
function ship:orbit( dt )
	--Figure based on the planet.
	local aSolarMass = solarMasses.objects[ 1 ]
	--Determine the distance between the ship and planet.
	local difX = aSolarMass.body:getX() - self.body:getX()
	local difY = aSolarMass.body:getY() - self.body:getY()
	local dist = hypotenuse( difX, difY )

	--Is the ship within range to orbit?  Need to know the max ship width ...
	--15 pixels is approximate for now, for half of max width
	if dist > aSolarMass.radius + 15 and dist < aSolarMass.radius * 8 then
		local dir = math.atan2( difY, difX )
		--Orbit velocity in pixels / second
		local scaledOrbitVel =
			( ( ( aSolarMass.body:getMass() ^ 2 ) * gravity /
				( ( self.body:getMass() + aSolarMass.body:getMass() ) *
				  dist * distanceScale )
			  ) ^ ( 1 / 2 )
			) * timeScale / distanceScale --Required velocity to orbit at current radius
		local orbitAngle = dir - quarterCircle --Perpendicular to angle to mass
		if orbitAngle < 0 then --Make it positive
			orbitAngle = maxAngle + orbitAngle
		end
		local velX, velY = self.body:getLinearVelocity()
		local orbVelX = math.cos( orbitAngle ) * scaledOrbitVel --X component
		local orbVelY = math.sin( orbitAngle ) * scaledOrbitVel --Y component
		local velDifX = orbVelX - velX --X component of force direction needed
		local velDifY = orbVelY - velY --Y component of force direction needed
		local forceAngle = math.atan2( velDifY, velDifX )
		lastAngle = scaledOrbitVel
		local forceVel = hypotenuse( velDifX, velDifY ) --Scalar in force direction

		--Apply 1/2 thrust in forceAngle direction ... use less force if needed
		local f = self.baseThrust * forceScale / 4 -- scaled force to apply
		--Compare velocity
		if forceVel < f * timeScale * dt / self.body:getMass() then
			f = forceVel * timeScale * dt * self.body:getMass()
		end
		self.body:applyForce( f * math.cos( forceAngle ), f * math.sin( forceAngle ) )
	end
end

--[[
--Uses world awareness to engage "warpdrive."
--Causes the ship to "wrap around" the borders of the world.
--]]
function ship:warpDrive()
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
--Ship's automatically respawn at the next available opportunity.
--This sets the controller to call for a respawn automatically.
--It also spawns 4 debris at the ship's destruction point.
--These debris will spawn above the soft cap in the configuration.
--]]
function ship:destroy()
	--self:deactivate()
	self.data.status = "DEAD"
	self.controller.state.respawn = true
	for i = 1,4 do
		local aDebris = junk:getNew( self.world, self.coordBag, "ship", self.body:getX(), self.body:getY() )
		game:addActive( aDebris )
		activeDebris = activeDebris + 1
	end
end

--[[
--Engages the laser, given sufficient charge.
--The laser fires from the ship to the mouse crosshair.
--Lasers travel extremely quickly, and inflict 1 damage/millisecond.
--]]
function ship:engageLaser( dt, x2, y2, endOfBeam )
	--Track usage and return if insufficient charge/energy.
	if self.data.laserCharge >= self.data.minimumLaserCharge then
		self.data.laserCharge = self.data.laserCharge - self.data.laserUse * timeScale * dt
	else
		return
	end
	--Create a laser beam "particle," really it's a rectangle.
	local x1 = self.body:getX()
	local y1 = self.body:getY()
--	print( theCamera:getX() + x2, theCamera:getY() + y2 )
	--Figure the correct angle and velocity on the X and Y directions.
	local angle = pointAngle( x1, y1, theCamera:getX() + x2 / theCamera.zoom, theCamera:getY() + y2 / theCamera.zoom )
	local xVel = math.cos( angle ) * lightSpeed
	local yVel = math.sin( angle ) * lightSpeed
	--Create the laser, own it with this ship, and add it to the game.
	local aLaserBeam = lasers:getNew( self.world, x1, y1, angle, self.coordBag, self, xVel, yVel )
	aLaserBeam:setOwner( self.controller )
	game:addActive( aLaserBeam )
end

--[[
--Launch a missile, given sufficient ammunition available.
--The missile fires from the cone of the ship in a straight line.
--Missiles slowly accelerate, and inflict a large amount of damage.
--]]
function ship:launchMissile( x, y )
	if self.data.missileBank > 0 then
		--Launch a missile, figure the correct position, angle, and velocity.
		local angle = self.body:getAngle()
		local x = self.body:getX() -- + math.cos( angle ) * 25
		local y = self.body:getY() -- + math.sin( angle ) * 25
		local xVel, yVel = self.body:getLinearVelocity()
		--Generate the missile, assign the owner, and add it to the game.
		local aMissile = missiles:getNew( self.world, x, y, angle, self.coordBag, self.shipConfig, xVel, yVel )
		aMissile:setOwner( self.controller )
		self.data.missiles[ #self.data.missiles + 1 ] = aMissile
--		self.data.newMissiles[ #self.data.newMissiles + 1 ] = aMissile
		self.data.missileBank = self.data.missileBank - 1
		game:addActive( aMissile )
	end
end

--[[
--WARNING: Old function, no longer in use.
function ship:getNewMissiles()
	local returnMissiles = {}
	returnMissiles = self.data.newMissiles
	self.data.newMissiles = nil
	self.data.newMissiles = {}
	return returnMissiles
end
--]]

--[[
--Get the number of remaining missiles.
--]]
function ship:getMissileBank()
	return self.data.missileBank
end

--[[
--Engage a tractor beam.
--WARNING: Function not currently implemented.
--]]
function ship:engageTractor()
end

--[[
--Respawn the ship in a random quadrant within 800 pixels of the borders.
--The ship will be pointed at a random angle.
--]]
function ship:respawn()
	self.data.status = "ACTIVE"
	x = math.random(0,800)
	y = math.random(0,800)
	--Figure out which side to spawn on.  0 is minimum X/Y, and 1 is maximum.
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
	--Reinitialize position and armor.
	self.body:setLinearVelocity(0,0)
	self.body:setAngularVelocity(0)
	self.data.armor = 2000
end

--[[] Returns the ship body for use by other classes, such as a camera!
function ship:getBody()
	return self.body
end--]]

--[[
--Get the ship's STEP acceleration.
--]]
function ship:getTurnAccel()
	return self.turnAccel
end

--[[
--Get the ship's X position
--]]
function ship:getX()
	return self.body:getX()
end

--[[
--Get the ship's Y position
--]]
function ship:getY()
	return self.body:getY()
end

--[[
--Get the points that make up the ship polygon
--]]
function ship:getPoints()
	return self.shipPoly:getPoints()
end

--[[
--Get the ship's current status
--]]
function ship:getStatus()
	return self.data.status
end

--[[
--Set the ship's current status
--]]
function ship:setStatus(stat)
	self.data.status = stat
end

--[[
--The type of the ship, which is determined by controller.
--]]
function ship:getType()
	return self.shipType
end

--[[
--Function to check maximum linear velocity.
--WARNING: Currently not in use!
--]]
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
