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

WARNING: Uses global solarMasses table from game.lua
WARNING: Uses global timeScale variable from game.lua
WARNING: Uses global activeDebris variable from game.lua
WARNING: Uses global missile, laser, and junk tables from game.lua
--]]

require "util/bodyObject.lua"
require "util/functions.lua"
require "util/missile.lua"
require "util/laser.lua"
require "util/explosion.lua"

-- Movement constants
local maxLinearV -- NOT CURRENTLY IN USE!
local maxAngleV
local baseThrust
local baseTorque
local easyTurn
local turnStep
local turnAccel

local maxMissile

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
--WARNING: Uses global timeScale variable!
--
--Requirement 3.1 to 3.4
--]]
function ship:construct( theWorld, controlledBy, aCoordBag, shipConfig )
	--Set the controller, and construct the ship.
	self.controller = controlledBy
	self:constructBody( theWorld, shipConfig.startX, shipConfig.startY, shipConfig.mass, shipConfig.mass * ( 15 * distanceScale ) ^ 2 / 6 )
	self.shipType = shipConfig.shipType

	--Set the initial angle for the ship.
	self.shipPoly = love.physics.newPolygonShape(self.body, 15, 0, -10, -10, -15, 0, -10, 10)
	self.body:setAngle( shipConfig.startAngle )

	--Initialize world awareness and store configuration data.
	self.coordBag = aCoordBag
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
	self.shipConfig = shipConfig
	self.mass = shipConfig.mass

	--Initialize propulsion constants.
	self.maxLinearV = 30 --NOT CURRENTLY IN USE!
	self.maxAngleV = 0.1 * timeScale --NOT CURRENTLY IN USE!
	self.baseThrust = shipConfig.mass * 500
	self.baseTorque = shipConfig.mass * 10 ^ 14
	self.easyTurn = 0.00003 * timeScale

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
	self.maxMissile = 10
	self.data.missileBank = self.maxMissile

	self.data.laserEngaged = false
	--laserCharge is modified by the timeScale.  IE: 500/200 = 2.5 seconds.
	self.data.laserCharge = 500 / timeScale
	self.data.laserUse = 1

	--Figure constants for the given timeScale
	self.reloadMissile = 600 / timeScale
	self.armMissile = 40 / timeScale
	self.maxLaser = 500 / timeScale

	--Timers to measure against constants
	self.missileTimer = 0
	self.rearmMissile = 40

	--Ship exhaust
	self.image = love.graphics.newImage("images/shipExhaust.png")
	self.exhaust = love.graphics.newParticleSystem(self.image,10)
	self.exhaust:setEmissionRate(20)
	self.exhaust:setLifetime(0.1)
	self.exhaust:setParticleLife(0.5)
	self.exhaust:setSpin(-2, 2)
	self.exhaust:setSpeed(150, 200)
	self.exhaust:setSpread(math.pi/2)
	self.exhaust:setSize(0.8)
end

--[[
--Draws the ship on the screen with the stored color.
--
--Requirement 3.4
--]]
function ship:draw()
	--If a ship is destroyed, then it shouldn't be drawn.
	--Used for the player's ship.
	if(not self.controller.state.respawn) then
		love.graphics.setColor( unpack( self.color ) )
		love.graphics.polygon( "fill", self.shipPoly:getPoints() )
		love.graphics.draw(self.exhaust, 0, 0)
	end
end

--[[
--Updates the ship every dt seconds.
--Polls the controller on every iteration for commands.
--If possible, executes the commands requested by the controller.
--
--Requirement 3.2
--]]
-- checks every dt seconds for commands, and execute the appropriate function
function ship:update( dt )
	--Get commands from controller
	local commands = self.controller:updateControls( self, dt )
	--Check for respawn
	if self.data.status == "DEAD" then
		self:stop()
		self.data.laserEngaged = false
		if commands[1] and commands[1][1] == "respawn" then
			self:respawn()
		end
	end
	--Charge laser and reload missiles
	if(self.data.missileBank < self.maxMissile) then
		self.missileTimer = self.missileTimer + dt
		if(self.missileTimer > self.reloadMissile) then
			self.data.missileBank = self.data.missileBank + 1
			self.missileTimer = 0
		end
	end
	if(self.rearmMissile < self.armMissile) then
		self.rearmMissile = self.rearmMissile + dt
	end
	if(self.data.laserCharge < self.maxLaser) then
		self.data.laserCharge = self.data.laserCharge + (dt / 4)
		if(self.data.laserCharge > self.maxLaser) then
			self.data.laserCharge = self.maxLaser
		end
	end

	--Execute all commands from controller
	for i, command in ipairs( commands ) do
		if command[1] == "stop" then
			self:stopThrust( dt )
		elseif command[1] == "thrust" then
			self:thrust()
		elseif command[1] == "reverse" then
			self:reverse()
		elseif command[1] == "stopRotation" then
			self:stopTurn()
		elseif command[1] == "easyLeft" then
			self:easyLeft()
		elseif command[1] == "normalLeft" then
			self:normalLeft()
		elseif command[1] == "stepLeft" then
			self:stepLeft()
		elseif command[1] == "easyRight" then
			self:easyRight()
		elseif command[1] == "normalRight" then
			self:normalRight()
		elseif command[1] == "stepRight" then
			self:stepRight()
		elseif command[1] == "orbit" then
			self:orbit( dt )
		elseif command[1] == "launchMissile" then
			self:launchMissile( command[2] )
		elseif command[1] == "engageLaser" then
			self.data.laserEngaged = true
		elseif command[1] == "disengageLaser" then
			self.data.laserEngaged = false
		end
	end
	--Start/continue laser beam
	if self.data.laserEngaged then
		self:engageLaser( dt, self.controller:getLaserCoords() )
	end
	--Sccelerate turn if using STEP mode.
	if self.turnAccel then
		self:accelTurn()
	end
	--Check boundary and activate the ship's warp drive if needed.
	self:warpDrive()
	--Emit particles
	self.exhaust:update(dt)
end

--[[
--A simple, constant turn to the left.
--
--Requirement 4.5
--]]
function ship:easyLeft()
	self.body:setAngle( self.body:getAngle() - self.easyTurn)
end

--[[
--An advanced, torque accelerated turn to the left.
--
--Requirement 4.6
--]]
function ship:normalLeft()
	self.body:applyTorque( -self.baseTorque * forceScale )
	--[[if self.body:getAngularVelocity() <= -self.maxAngleV then
		self.body:setAngularVelocity(-self.maxAngleV)
	end--]]
end

--[[
--An advanced turn to the left that causes the ship to continue rotating at a certain speed.
--NO LONGER IN USE
--]]
function ship:stepLeft()
	self.turnAccel = true
	self.turnStep = self.turnStep - 1
end

--[[
--A simple, constant turn to the right.
--
--Requirement 4.5
--]]
function ship:easyRight()
	self.body:setAngle( self.body:getAngle() + self.easyTurn)
end

--[[
--An advanced, torque accelerated turn to the right.
--
--Requirement 4.6
--]]
function ship:normalRight()
	self.body:applyTorque( self.baseTorque * forceScale )
	--[[if self.body:getAngularVelocity() >= self.maxAngleV then
		self.body:setAngularVelocity(self.maxAngleV)
	end--]]
end

--[[
--An advanced turn to the right that causes the ship to continue rotating at a certain speed.
--NO LONGER IN USE
--]]
function ship:stepRight()
	self.turnAccel = true
	self.turnStep = self.turnStep + 1
end

--[[
--Used in STEP mode to accelerate the constant turn rate.
--NO LONGER IN USE
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
--
--Requirement 4.7
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
--
--Requirement 4.2
--]]
function ship:thrust()
	local scaledThrust = self.baseThrust * forceScale
	local angle = self.body:getAngle()
	--Apply the proper amount of thrust in the X and Y directions.
	local xThrust = math.cos( angle ) * scaledThrust
	local yThrust = math.sin( angle ) * scaledThrust
	self.body:applyForce( xThrust, yThrust )
	--Generate some particles
	self.exhaust:setPosition(self.body:getX() - math.cos(angle) * 20,self.body:getY() - math.sin(angle) * 20)
	self.exhaust:setDirection(angle - math.pi)
	self.exhaust:start()
end

--[[
--Applies thrust to the ship, pointed in the opposite direction of the cone
--Reversing occurs at 1/2 normal thrust.
--
--Requirement 4.3
--]]
function ship:reverse()
	local halfThrustScaled = self.baseThrust * forceScale / 2
	local angle = self.body:getAngle()
	--Apply the proper amount of thrust in the X and Y directions.
	local xThrust = math.cos( angle ) * halfThrustScaled
	local yThrust = math.sin( angle ) * halfThrustScaled
	self.body:applyForce( -xThrust, -yThrust  )
	--Generate some particles
	self.exhaust:setPosition(self.body:getX() - math.cos(angle) * 20,self.body:getY() - math.sin(angle) * 20)
	self.exhaust:setDirection(angle - math.pi)
	self.exhaust:start()
end

--[[
--Applies thrust to the ship, pointed in the opposite direction of MOVEMENT
--All stop occurs at 1/2 normal thrust.
--
--Requirement 4.4
--]]
function ship:stopThrust( dt )
	local xVel, yVel = self.body:getLinearVelocity()
	local halfThrustScaled = self.baseThrust * forceScale / 3
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
	--Generate some particles
	self.exhaust:setPosition(self.body:getX() - math.cos(self.body:getAngle()) * 20,self.body:getY() - math.sin(self.body:getAngle()) * 20)
	self.exhaust:setDirection(self.body:getAngle() - math.pi)
	self.exhaust:start()
end

--[[
--Applies thrust to the ship to orbit the nearest planet
--WARNING: Uses the global solarMasses table.
--WARNING: Uses global timeScale variable.
--
--Requirement 4.9
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
--When ships are destroyed, they must be respawned.
--This sets the controller to call for a respawn until the command is given.
--It also spawns 1-4 debris at the ship's destruction point.
--These debris will spawn above the soft cap in the configuration.
--WARNING: Uses global explosions table.
--WARNING: Uses global activeDebris variable.
--WARNING: Uses global junk table.
--
--Requirement 11
--]]
function ship:destroy()
	self:deactivate()
	self.data.status = "DEAD"
	self.controller.state.respawn = true
	local velX, velY = self.body:getLinearVelocity()
	local explode = explosions:getNew(self.body:getX(),self.body:getY(),velX,velY,1,20)
	game:addEffect( explode )

	--Create the debris from the destroyed ship.
	local tempMass = math.random(50,75)/100 * self.mass
	local numSpawn = math.random(1,4)
	for i = 1,numSpawn do
		local aDebris = {}
		if(i == numSpawn) then
			aDebris = junk:getNew( self.world, self.coordBag, "ship", self.body:getX(), self.body:getY(), velX, velY, tempMass )
		else
			tempMass2 = math.random(10,15)/100 * tempMass
			tempMass = tempMass - tempMass2
			aDebris = junk:getNew( self.world, self.coordBag, "ship", self.body:getX(), self.body:getY(), velX, velY, tempMass2 )
		end
		game:addActive( aDebris )
		activeDebris = activeDebris + 1
	end
end

--[[
--Respawn the ship in a random quadrant within 800 pixels of the borders.
--The ship will be pointed at a random angle.
--
--Requirement 10.2
--]]
function ship:respawn()
	self:activate()
	game:addActive( self )
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
	--self.data.laserCharge = 500 / timeScale
	self.data.missileBank = self.maxMissile
	self.controller.state.respawn = false
end

--[[
--Engages the laser, given sufficient charge.
--The laser fires from the ship to the given target (cross-hair or object).
--Lasers travel extremely quickly, and inflict 1 damage/millisecond.
--WARNING: Uses global laser table.
--
--Requirement 8.1
--]]
function ship:engageLaser( dt, target )
	local x2 = 0
	local y2 = 0
	-- determine coordinates by target type
	if target.body then -- get coordinates from target body
		x2 = target.body:getX()
		y2 = target.body:getY()
	else -- adjust coordinates for camera position
		--x2 = theCamera:getX() + target.x / theCamera.zoom
		--y2 = theCamera:getY() + target.y / theCamera.zoom
		x2 = target.x
		y2 = target.y
	end
	--Track usage and return if insufficient charge/energy.
	if self.data.laserCharge >= dt then
		self.data.laserCharge = self.data.laserCharge - dt
	else
		return
	end
	--Create a laser beam "particle," really it's a rectangle.
	local x1 = self.body:getX()
	local y1 = self.body:getY()
--	print( theCamera:getX() + x2, theCamera:getY() + y2 )
	--Figure the correct angle and velocity on the X and Y directions.
	local angle = pointAngle( x1, y1, x2, y2 )
	local xVel = math.cos( angle ) * lightSpeed
	local yVel = math.sin( angle ) * lightSpeed
	--Create the laser, own it with this ship, and add it to the game.
	local aLaserBeam = lasers:getNew( self.world, x1, y1, angle, self.coordBag, self, xVel, yVel )
	aLaserBeam:setOwner( self.controller )
	game:addActive( aLaserBeam )
end

--[[
--Returns the remaining laser energy.
--
--Requirement 8.2
--]]
function ship:getLaserEnergy()
	return self.data.laserCharge
end

--[[
--Add the list of enemy ships to the current ship.
--Used in launchMissile for targeting purposes.
--
--Requirement 9.1
--]]
function ship:addTargets(shipList)
	self.targets = {}
	self.targets = shipList
end

--[[
--Launch a missile, given sufficient ammunition available.
--The missile fires from the ship and travels towards its target.
--Missiles slowly accelerate, and inflict a large amount of damage.
--WARNING: Uses global missile table.
--
--Requirement 9.1
--]]
function ship:launchMissile( target )
	if (self.rearmMissile >= self.armMissile) then
		if self.data.missileBank > 0 then
			--Launch a missile, figure the correct position, angle, and velocity.
			local angle = self.body:getAngle()
			local x = self.body:getX() -- + math.cos( angle ) * 25
			local y = self.body:getY() -- + math.sin( angle ) * 25
			local xVel, yVel = self.body:getLinearVelocity()
			--Generate the missile, assign the owner, and add it to the game.
			local aMissile = missiles:getNew( self.world, x, y, angle, self.coordBag, self.shipConfig, xVel, yVel )
			aMissile:setOwner( self.controller )
			--Find the closest valid target
			local curDist = 9999999
			if target == nil then -- find closest ship target
				for i, v in pairs(self.targets) do
					dist = pointDistance(self.body:getX(),self.body:getY(),v.body:getX(),v.body:getY())
					if(dist < curDist) then
						curDist = dist
						target = v
					end
				end
			end
		--If there's a target, then set it as the missile's target
			if(target ~= nil) then
				aMissile:setTarget(target)
			end
	--		self.data.missiles[ #self.data.missiles + 1 ] = aMissile
	--		self.data.newMissiles[ #self.data.newMissiles + 1 ] = aMissile
			self.data.missileBank = self.data.missileBank - 1
			game:addActive( aMissile )

			self.rearmMissile = 0
		end
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
--
--Requirement 7.2
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
--Stops the ship dead in the water when it is destroyed.
--Essentially used only for players, as they do not instantly respawn.
--]]
function ship:stop()
	self.body:setLinearVelocity(0,0)
	self.body:setAngularVelocity(0)
end

--[[] Returns the ship body for use by other classes, such as a camera!
function ship:getBody()
	return self.body
end--]]

--[[
--Returns a ship's remaining armor.
--]]
function ship:getArmor()
	return self.data.armor
end

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
