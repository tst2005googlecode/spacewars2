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

require "util/bodyObj.lua"
require "util/functions.lua"

-- Movement constants
local maxLinearV -- NOT CURRENTLY IN USE!
local maxAngleV
local baseThrust
local baseTorque
local easyTurn
local turnStep
local turnAccel

ship = bodyObj:new(...)

-- Function to initialize the ship body, shape, angle, and border awareness
function ship:init( theWorld, startX, startY, startAngle, aCoordBag, shipConfig )
	--if shipConfig == nil then ship:error() end
	self:initBody( theWorld, startX, startY, shipConfig.mass, shipConfig.mass * ( 25 * 10 ) * ( 100000 ^ 2 ) / 6 )
	-- initial angle is 0 (right), so point ship to the right
	self.shipPoly = love.physics.newPolygonShape(self.body, 15, 0, -10, 10, -10, -10, -12, 0)
	self.body:setAngle(startAngle)

	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()

	-- these need to be set from shipConfig
	self.maxLinearV = 30 --NOT CURRENTLY IN USE!
	self.maxAngleV = 0.1 * timeScale
	self.baseThrust = shipConfig.mass * 400
	self.baseTorque = shipConfig.mass ^ 3 * 10000
	self.easyTurn = 0.005 / timeScale

	-- state controls for step turning
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
	local solarMass = solarMasses[1] -- get nearest mass later
    local difX = solarMass.body:getX() - self.body:getX()
    local difY = solarMass.body:getY() - self.body:getY()
    local dist = hypotenuse( difX, difY )
    
    -- Is the ship within range to orbit?  Need to know the max ship width ...
    -- 15 pixels is approximate for now, for half of max width
    if dist > solarMass.radius + 15 and dist < solarMass.radius * 8 then
        local dir = math.atan2( difY, difX )
        -- orbit velocity in pixels / second
        local scaledOrbitVel = 
            ( ( ( solarMass.body:getMass() ^ 2 ) * gravity /
                ( ( self.body:getMass() + solarMass.body:getMass() ) * 
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
    
--[[ modified old code from Game Maker ...
        newThrust = maxThrust / 2;
        Dif = Dir - direction;
        if (Dif < 0)
        {
            Dif +=360;
        }

        -- always move into clockwise orbit
        Vx = v - math.cos(Dif - 90) * speed ;
        Vy = -math.sin( Dif - 90 ) * speed;
        V = sqrt(sqr(Vy) + sqr(Vx));
        T = point_direction(0, 0, Vx, Vy);
        newThrustDir = Dir - 90 - T;

        if (V < newThrust)
        {
            newThrust = V;
        }
        if ((newThrust < .05)) // If tiny course correction, set path
        {
            if (Dif < 180)
            {
                --scrOrbitCW(id,Dir,Dis,v);
-- argument0 = id, argument1 = Dir, argument2 = Dis, argument3 = v
    with (argument0)
    {
        motion_set(argument1 - 90, argument3);
        path_index = 0;
        path_scale = argument2 / 140;
        path_position = 0;
        path_orientation = argument1 - 180;
    }
            }
            else
            {
                --scrOrbitCCW(id,Dir,Dis,v);
-- argument0 = id, argument1 = Dir, argument2 = Dis, argument3 = v
    with (argument0)
    {
        motion_set(argument1 + 90, argument3);
        path_index = 1;
        path_scale = argument2 / 140;
        path_position = 0;
        path_orientation = argument1 - 180;
    }            }
            return true;
        }
        else // Else, apply course correction
        {
            motion_add(newThrustDir, newThrust);
            return false;
        }
    } // End withing range to orbit
}--]]
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

-- Fires a laser
function ship:laser()
end

-- Fires a missile
function ship:missile()
end

-- Fires a tractor beam
function ship:tractor()
end

--[[] Returns the ship body for use by other classes, such as a camera!
function ship:getBody()
	return self.body
end--]]

function ship:getTurnAccel()
	return self.turnAccel
end

function ship:getX()
	return self.body:getX()
end

function ship:getY()
	return self.body:getY()
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
