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

This class implements a player controlled ship.
The ship used is an instance of ship.lua.
playerShip checks for keyboard input.
	Then it activates the appropriate ship function.
--]]

require "subclass/class.lua"
require "util/ship.lua"

playerShip = class:new(...)

--Function to instantiate the ship and assign keyboard controls
function playerShip:init(theWorld, startX, startY, startAngle, aCoordBag, shipConfig)
	-- Create the ship bound to this instance
	self.theShip = ship:new(theWorld,startX,startY,startAngle,aCoordBag)
	-- Assign the key commands
	self.thrustKey,self.leftKey,self.reverseKey,self.rightKey,self.stopTurnKey,self.stopThrustKey,self.turnMode = shipConfig:getAllControls()
end

--Draw the ship using its draw() function
function playerShip:draw()
	love.graphics.setColor(unpack(color["ship"]))
	self.theShip:draw()
end

--Checks every dt seconds for input, and executes the appropriate function
function playerShip:update(dt)
	--Thrust controls
	if love.keyboard.isDown(self.thrustKey) then
		self.theShip:thrust()
	end
	--Turn left
	if love.keyboard.isDown(self.leftKey) then
		if(self.turnMode == "EASY") then
			self.theShip:easyLeft()
		else
			self.theShip:normalLeft()
		end
	end
	--Turn right
	if love.keyboard.isDown(self.rightKey) then
		if(self.turnMode == "EASY") then
			self.theShip:easyRight()
		else
			self.theShip:normalRight()
		end
	end
	--Stop turning
	if love.keyboard.isDown(self.stopTurnKey) then
		self.theShip:stopTurn()
	end
	--Stop thrust OR reverse thrust.  NOT both.
	if love.keyboard.isDown(self.stopThrustKey) then
		self.theShip:stopThrust()
	elseif love.keyboard.isDown(self.reverseKey) then
		self.theShip:reverse()
	end
	--Activate the ship's warpdrive if needed.
	self.theShip:warpDrive()
end

--Passes the ship's body up the stack.
function playerShip:getBody()
	return self.theShip:getBody()
end
