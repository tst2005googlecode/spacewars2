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

a planet, moon, etc ... that has a high mass which will affect all other objects
in the game area

--]]

require "subclass/class.lua"

-- attributes
local color
local orbit
local radius

-- Box2D variables
local body = {}
local massShape = {}

solarMass = class:new(...)

-- Function to initialize the mass
function solarMass:init( pWorld, pX, pY, pMass, pRadius, pOrbit, pColor )
	self.color = pColor
	self.orbit = pOrbit
    self.radius = pRadius
	self.body = love.physics.newBody( pWorld, pX, pY, pMass, 1 )
	self.massShape = love.physics.newCircleShape( self.body, 0, 0, pRadius )
--	self.massShape:setMask(1)
	self.massShape:setSensor(true)

	self.data = {}
	self.data.status = "SOLAR"
	self.massShape:setData(self.data)
end

function solarMass:draw()
	love.graphics.setColor( self.color )
	love.graphics.circle( "fill", self.body:getX(), self.body:getY(), self.massShape:getRadius(), 100 )
end

function solarMass:update( dt )
	if self.orbit > 0 then
		self.orbitAngle = self.orbitAngle + self.radialVelocity * dt * timeScale
		if self.orbitAngle > maxAngle then
			self.orbitAngle = self.orbitAngle - maxAngle
		end
		self.body:setX( self.originX + math.cos( self.orbitAngle ) * self.orbitRadius )
		self.body:setY( self.originY + math.sin( self.orbitAngle ) * self.orbitRadius )
	end
end

function solarMass:applyGravity( object, dt )
	local theBody = object:getBody()
	local difX = ( self.body:getX() - theBody:getX() ) * distanceScale
	local difY = ( self.body:getY() - theBody:getY() ) * distanceScale
	local dir = math.atan2( difY, difX )
	local dis2 = ( difX ^ 2 + difY ^ 2 ) -- ^ ( 1 / 2 )
	local fG = gravity * ( self.body:getMass() * theBody:getMass() ) / dis2

	fG = fG * forceScale -- now scaled to pixels / s ^ 2
	theBody:applyForce( math.cos( dir ) * fG , math.sin( dir ) * fG )
end

--[[
function applyGravity( solarMass, object, dt )
--	local difX = ( solarMass.body:getX() - object.body:getX() ) * distanceScale
--	local difY = ( solarMass.body:getY() - object.body:getY() ) * distanceScale
	local difX = ( solarMass.body:getX() - object:getBody():getX() ) * distanceScale
	local difY = ( solarMass.body:getY() - object:getBody():getY() ) * distanceScale
	local dir = math.atan2( difY, difX )
	local dis2 = ( difX ^ 2 + difY ^ 2 ) -- ^ ( 1 / 2 )
	--local aG = gravity * ( solarMass.body:getMass() + object.body:getMass() ) /
    --                     ( dis2 * distanceScale )
--	local fG = gravity * ( solarMass.body:getMass() * object.body:getMass() ) / dis2
	local fG = gravity * ( solarMass.body:getMass() * object:getBody():getMass() ) / dis2

    fG = fG * forceScale -- now scaled to pixels / s ^ 2
--[
if lastA == 0 then lastA = fG end
if lastA > highA then highA = fG end
if lastA < lowA then lowA = fG end
--]
	object:getBody():applyForce( math.cos( dir ) * fG , math.sin( dir ) * fG )
end
]]--

function solarMass:getX()
	return self.body:getX()
end

function solarMass:getY()
	return self.body:getY()
end

function solarMass:getRadius()
	return self.massShape:getRadius()
end

function solarMass:getType()
	return "solarMass"
end
