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

-- Box2D variables
local massBody = {}
local massShape = {}

solarMass = class:new(...)

-- Function to initialize the mass
function solarMass:init( pWorld, pX, pY, pMass, pRadius, pOrbit, pColor )
	self.color = pColor
	self.orbit = pOrbit
	self.massBody = love.physics.newBody( pWorld, pX, pY, pMass, 1 )
	self.massShape = love.physics.newCircleShape( self.massBody, 0, 0, pRadius )
	self.massShape:setMask(1)
end

function solarMass:draw()
	love.graphics.setColor( self.color )
	love.graphics.circle( "fill", self.massBody:getX(), self.massBody:getY(), self.massShape:getRadius(), 100 )
end

function solarMass:update( dt )
	if self.orbit > 0 then
		self.orbitAngle = self.orbitAngle + self.angularVelocity * dt
		if self.orbitAngle > maxAngle then
			self.orbitAngle = self.orbitAngle - maxAngle
		end
		self.massBody:setX( self.originX + math.cos( self.orbitAngle ) * self.orbitRadius )
		self.massBody:setY( self.originY + math.sin( self.orbitAngle ) * self.orbitRadius )
	end
end
