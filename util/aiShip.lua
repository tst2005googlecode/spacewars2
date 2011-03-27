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

aihip.lua

This class implements an ai controlled ship.
The ship used is an instance of ship.lua.
aiShip chooses a random spawn point and direction.
	Then it flies for 600 update cycles before killing ignition.
--]]

require "subclass/class.lua"
require "util/ship.lua"

local theShip

aiShip = class:new(...)

--Function to instantiate the ship.
function aiShip:init(theWorld,aCoordBag,shipConfig)
	local startX = math.random(0,aCoordBag:getMaxX())
	local startY = math.random(0,aCoordBag:getMaxY())
	local startAngle = math.random() * maxAngle
	self.theShip = ship:new(theWorld,startX,startY,startAngle,aCoordBag, shipConfig)
	self.theShip:setStatus("AISHIP")
	self.fuel = 600
end

--Draw the aiShip
function aiShip:draw()
	love.graphics.setColor(unpack(color["ai"]))
	self.theShip:draw()
end

function aiShip:update(dt)
	-- aiShips currently respawn instantaneously
	if(self.theShip:getStatus() == "DEAD") then
		self.theShip:respawn()
		self.theShip:setStatus("AISHIP")
		self.fuel = 600
	--If the aiShip has fuel, then it can still thrust
	elseif(self.fuel > 0) then
		self.theShip:thrust()
		self.fuel = self.fuel - 1
	end
	--If the aiShip reaches a border, then warp it!
	self.theShip:warpDrive()
end

-- the ai's ship
function aiShip:getShip()
	return self.theShip
end

-- the AI's X position
function aiShip:getX()
	return self.theShip:getX()
end

-- the AI's Y position
function aiShip:getY()
	return self.theShip:getY()
end

-- the AI's type
function aiShip:getType()
	return "aiShip"
end
