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

explosion.lua

Wrapper class for a particle system simulating an explosion.
Allows explosions to be delinked from the object creating them.
--]]

require "subclass/class.lua"

explosion = class:new(...)

--[[
--Constructs an explosion with default parameters.
--Then calls the initialization function to assign parameters.
--
--Requirement 11
--]]
function explosion:construct(x,y,size,rate)
	self.image = love.graphics.newImage("images/explosion.png")
	self.explode = love.graphics.newParticleSystem(self.image,200)
	self.explode:setEmissionRate(20)
	self.explode:setLifetime(2)
	self.explode:setParticleLife(0.5)
	self.explode:setSpin(0,0)
	self.explode:setSpeed(100,100)
	self.explode:setSpread(math.pi*2)
	self.explode:setSize(1)
	self:init(x,y,size,rate)
end

--[[
--Initializes a newly constructed or recycled explosion.
--
--Requirement 11
--]]
function explosion:init(x,y,size,rate)
	self.x = x
	self.y = y
	self.explode:setPosition(x,y)
	self.explode:setDirection(0)
	self.explode:setSize(size)
	self.explode:setEmissionRate(rate)
	self.explode:start()
	self:activate()
end

--[[
--Draws the explosion to the screen.
--
--Requirement 11
--]]
function explosion:draw()
	love.graphics.draw(self.explode,0,0)
end

--[[
--Updates the particles in the system.
--If the lifetime of the generator is dead, it will destroy itself.
--Destruction only occurs if all particles are ALSO dead.
--
--Requirement 11
--]]
function explosion:update(dt)
	if(not self.explode:isActive()) then
		if(self.explode:count() == 0) then
			self:destroy()
			return
		end
	end
	self.explode:update(dt)

end

--[[
--Deactivates and recycles a used explosion.
--]]
function explosion:destroy()
	self:deactivate()
	explosions:recycle(self)
end

--[[
--Returns the X position of the explosion.
--]]
function explosion:getX()
	return self.x
end

--[[
--Returns the Y position of the explosion.
--]]
function explosion:getY()
	return self.y
end

--[[
--Returns the type of the explosion, "explosion".
--]]
function explosion:getType()
	return "explosion"
end

--[[
--Marks the explosion as being active.
--]]
function explosion:activate()
	self.isActive = true
end

--[[
--Marks the explosion as being inactive.
--]]
function explosion:deactivate()
	self.isActive = false
end

--[[
--Returns the activity of the explosion.
--]]
function explosion:getActive()
	return self.isActive
end
