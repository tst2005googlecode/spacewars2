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

solarMass.lua

Implements a planet, moon, or other heavenly body.
These bodies have a high mass and affect all other objects in the game area.
--]]

require "subclass/class.lua"

-- attributes
local color
local orbit
local radius
local data

-- Box2D variables
local body = {}
local massShape = {}

solarMass = class:new(...)

--[[
--Constructs and initializes a solarMass.
--Sets the size and mass, which are basic parameters.
--The advanced moon parameters for orbit are set in the game.
--
--Requirement 6.1 to 6.2
--]]
function solarMass:construct( pWorld, pX, pY, pMass, pRadius, pOrbit, pColor )
	self.color = pColor
	self.orbit = pOrbit
	self.radius = pRadius
	self.body = love.physics.newBody( pWorld, pX, pY, pMass, 1 )
	self.massShape = love.physics.newCircleShape( self.body, 0, 0, pRadius )
	self.massShape:setSensor(true)

	self.data = {}
	self.objectType = types.solarMass
	self.massShape:setData(self)
end

--[[
--Draws the solarMass to the screen.
--]]
function solarMass:draw()
	love.graphics.setColor( self.color )
	love.graphics.circle( "fill", self.body:getX(), self.body:getY(), self.massShape:getRadius(), 100 )
end

--[[
--Updates the solarMass's position in the game world.
--The planet does not move, and is represented by orbit = 0.
--Moons move on a set orbit determined by its distance from the planet.
--
--Requirement 6.2
--]]
function solarMass:update( dt )
	if self.orbit > 0 then
		--Calculate the moon's new angle in relation to the planet.
		self.orbitAngle = self.orbitAngle + self.radialVelocity * dt * timeScale
		if self.orbitAngle > maxAngle then
			self.orbitAngle = self.orbitAngle - maxAngle
		end
		--Set the moon's new position based on the angle.
		self.body:setX( self.originX + math.cos( self.orbitAngle ) * self.orbitRadius )
		self.body:setY( self.originY + math.sin( self.orbitAngle ) * self.orbitRadius )
	end
end

--[[
--Applys a force to an object based on the solarMass's mass and distance.
--Not currently in use in favor of utilizing the funciton in game.lua
--]]
function solarMass:applyGravity( object, dt )
	local theBody = object:getBody()
	--Find the distance on the X and Y axis.
	local difX = ( self.body:getX() - theBody:getX() ) * distanceScale
	local difY = ( self.body:getY() - theBody:getY() ) * distanceScale
	--Find the angle between the two objects.
	local dir = math.atan2( difY, difX )
	--Find the hypotenuse of the X and Y directions.
	local dis2 = ( difX ^ 2 + difY ^ 2 ) -- ^ ( 1 / 2 )
	--Determine the force to apply, and scale it.
	local fG = gravity * ( self.body:getMass() * theBody:getMass() ) / dis2
	fG = fG * forceScale -- now scaled to pixels / s ^ 2
	--Apply the force to the body.
	theBody:applyForce( math.cos( dir ) * fG , math.sin( dir ) * fG )
end

--[[
--Get the X position of the solarMass.
--]]
function solarMass:getX()
	return self.body:getX()
end

--[[
--Get the Y position of the solarMass.
--]]
function solarMass:getY()
	return self.body:getY()
end

--[[
--Get the radius of the solarMass.
--]]
function solarMass:getRadius()
	return self.massShape:getRadius()
end

--[[
--Get the type of the solarMass, which is "solarMass".
--]]
function solarMass:getType()
	return "solarMass"
end
