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

playerShip.lua

This class implements a dummy controlled ship.
The ship used is an instance of ship.lua.
dummyShip chooses a random spawn point and direction.
	Then it flies for 600 update cycles before killing ignition.
--]]

require "subclass/class.lua"
require "util/ship.lua"

dummyShip = class:new(...)

--Function to instantiate the ship.
function dummyShip:init(theWorld,aCoordBag)
	local startX = math.random(0,aCoordBag:getMaxX())
	local startY = math.random(0,aCoordBag:getMaxY())
	local startAng = (math.random(1,628))/100
	self.theShip = ship:new(theWorld,startX,startY,startAng,aCoordBag)
--	self.theShip = ship:new(theWorld,aCoordBag:getMaxX()/4,aCoordBag:getMaxY()/4,startAng,aCoordBag)
	self.fuel = 600
end

function dummyShip:draw()
	love.graphics.setColor(unpack(color["ship"]))
	self.theShip:draw()
end

function dummyShip:update(dt)
	if(self.fuel > 0) then
		self.theShip:thrust()
		self.fuel = self.fuel - 1
	end
	self.theShip:warpDrive()
end

function dummyShip:getX()
	return self.theShip:getX()
end

function dummyShip:getY()
	return self.theShip:getY()
end

function dummyShip:getType()
	return "dummyShip"
end
