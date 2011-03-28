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

local theShip

playerShip = class:new(...)

--Function to instantiate the ship and assign keyboard controls
function playerShip:init(theWorld, startX, startY, startAngle, aCoordBag, shipConfig)
	-- Create the ship bound to this instance
	self.theShip = ship:new(theWorld,startX,startY,startAngle,aCoordBag,shipConfig)
	self.theShip:setStatus("PLAYERSHIP")
	-- Assign the key commands
	self.thrustKey,self.leftKey,self.reverseKey,self.rightKey,self.stopTurnKey,self.stopThrustKey,self.orbitKey,self.turnMode = shipConfig:getAllControls()

	self.missiles = {}
	self.newMissiles = {}
	self.missileBank = 10
end

--Draw the ship using its draw() function
function playerShip:draw()
	love.graphics.setColor(unpack(color["ship"]))
	self.theShip:draw()
end

function playerShip:keypressed(key)
	if self.turnMode == "STEP" then
		if key == theConfigBag:getLeft() then
			self.theShip:stepLeft()
		elseif key == theConfigBag:getRight() then
			self.theShip:stepRight()
		end
	end
end

function playerShip:mousepressed(x,y,button)
	--Fire missile on right mouse click if the ship is alive
	if(button == "r" and self.theShip:getStatus() ~= "DEAD") then
		if(self.missileBank > 0) then
			local aMissile = self.theShip:missile()
			aMissile:setOwner("PLAYERSHIP")
			self.missiles[#self.missiles+1] = aMissile
			self.newMissiles[#self.newMissiles+1] = aMissile
			self.missileBank = self.missileBank - 1
			aMissile = nil
		end
	end
end

--Checks every dt seconds for input, and executes the appropriate function
function playerShip:update(dt)
	if(self.theShip:getStatus() == "DEAD") then
	else
		--Checking for dead missiles is always a vaild operation
		for i,missile in ipairs(self.missiles) do
			if missile:getStatus() == "DEAD" then
				table.remove(self.missiles,i)
				self.missileBank = self.missileBank + 1
			end
		end
		--Thrust controls
		if love.keyboard.isDown(self.thrustKey) then
			self.theShip:thrust()
		end
		--Turn left
		if love.keyboard.isDown( self.leftKey ) then
			if ( self.turnMode == "EASY" ) then
				self.theShip:easyLeft()
			elseif ( self.turnMode == "NORMAL" ) then
				self.theShip:normalLeft()
			end
		end
		--Turn right
		if love.keyboard.isDown( self.rightKey ) then
			if ( self.turnMode == "EASY" ) then
				self.theShip:easyRight()
			elseif ( self.turnMode == "NORMAL" ) then
				self.theShip:normalRight()
			end
		end
		-- accelerate turn if turning
		if self.theShip:getTurnAccel() then
			self.theShip:accelTurn()
		end
		--Stop turning
		if love.keyboard.isDown(self.stopTurnKey) then
			self.theShip:stopTurn()
		end
		-- orbit planet
		if love.keyboard.isDown(self.orbitKey) then
			self.theShip:orbit( dt )
		end
		--Stop thrust OR reverse thrust.  NOT both.
		if love.keyboard.isDown(self.stopThrustKey) then
			self.theShip:stopThrust( dt )
		elseif love.keyboard.isDown(self.reverseKey) then
			self.theShip:reverse()
		end
		--Activate the ship's warpdrive if needed.
		self.theShip:warpDrive()
	end
end

-- Respawn the player's ship
function playerShip:respawn()
	self.theShip:respawn()
	self.theShip:setStatus("PLAYERSHIP")
end

--Passes the ship's body up the stack.
function playerShip:getBody()
	return self.theShip:getBody()
end

-- the player's ship
function playerShip:getShip()
	return self.theShip
end

-- the player's new missiles
function playerShip:getNewMissiles()
	local returnMissiles = {}
	returnMissiles = self.newMissiles
	self.newMissiles = nil
	self.newMissiles = {}
	return returnMissiles
end

-- the player's remaining missiles
function playerShip:getMissileBank()
	return self.missileBank
end

-- the player's X position
function playerShip:getX()
	return self.theShip:getX()
end

-- the player's Y position
function playerShip:getY()
	return self.theShip:getY()
end

-- the points making up the player's polygon
function playerShip:getPoints()
	return self.theShip:getPoints()
end

-- the type of ship this is
function playerShip:getType()
	return "playerShip"
end
