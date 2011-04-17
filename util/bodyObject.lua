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

bodyObject.lua ... a superclass; part of object framework

An object that exists in the "world".
It has position, mass, and rotational inertia.
It also records active state for drawing/update purposes.
--]]

require "subclass/class.lua"

-- Box2D variable
local body

local isActive
local index
local objectType

bodyObject = class:new(...)

--[[
--Constructs and initializes a body with the specified coordinates and mass.
--]]
function bodyObject:constructBody( pWorld, pX, pY, pMass, pRotateInertia )
	self.body = love.physics.newBody( pWorld, pX, pY, pMass, pRotateInertia )
	self.isActive = true
end

--[[
--Returns the body for any functions that need it for calculations.
--]]
function bodyObject:getBody()
	return self.body
end

--[[
--Activates a body to supply it for drawing and updating.
--]]
function bodyObject:activate()
	self.isActive = true
end

--[[
--Deactivates a body to remove it from drawing and updating.
--]]
function bodyObject:deactivate()
	self.isActive = false
end
