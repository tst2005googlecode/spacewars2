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

player.lua

This class implements a player control.  This checks the mouse and keyboard for
player input, which is supplied to the ship as commands on each update
--]]

require "subclass/class.lua"

local state
local shipState

player = class:new(...)

--Function to instantiate the ship and assign keyboard controls
function player:construct( aCoordBag, shipConfig )
	-- Assign the key commands
	self.thrustKey,self.leftKey,self.reverseKey,self.rightKey,self.stopTurnKey,self.stopThrustKey,self.orbitKey,dummy1,dummy2,self.turnMode = shipConfig:getAllControls()
	self.state = { stepLeft = false, stepRight = false, launchMissile = false, engageLaser = false, disengageLaser = false, respawn = false }
	self.shipState = { missileBank = 0 }
end

function player:keypressed( key )
	if self.turnMode == "STEP" then
		if key == theConfigBag:getLeft() then
			state.stepLeft = true
		elseif key == theConfigBag:getRight() then
			state.stepRight = true
		end
	end
end

function player:mousepressed( x, y, button )
	if ( button == "r" ) then -- launch missile on right mouse click
		self.state.launchMissile = true
	end -- engage laser on left mouse click
	if ( button == "l" ) then
		self.state.engageLaser = true
	end
end

function player:mousereleased( x, y, button )
	-- disengage laser on left mouse up
	if ( button == "l" ) then
		self.state.disengageLaser = true
	end
end

function player:updateControls( theShipState )
	self.shipState = theShipState
	local commands = {}

	if self.state.respawn then
		self.state.respawn = false
		return { "respawn" }
	end

	-- stop motion ...
	if love.keyboard.isDown(self.stopThrustKey) then
		commands[ #commands + 1 ] = "stop"
	else
		-- or, foward or reverse thrust
		if love.keyboard.isDown( self.thrustKey ) then
			commands[ #commands + 1 ] = "thrust"
		elseif love.keyboard.isDown(self.reverseKey) then
			commands[ #commands + 1 ] = "reverse"
		end
	end
	-- stop rotation
	if love.keyboard.isDown(self.stopTurnKey) then
		commands[ #commands + 1 ] = "stopRotation"
	else
		-- rotate left
		if self.state.stepLeft then
			commands[ #commands + 1 ] = "stepLeft"
		else
			if love.keyboard.isDown( self.leftKey ) then
				if ( self.turnMode == "EASY" ) then
					commands[ #commands + 1 ] = "easyLeft"
				elseif ( self.turnMode == "NORMAL" ) then
					commands[ #commands + 1 ] = "normalLeft"
				end
			end
		end
		-- rotate right
		if self.state.stepLeft then
			commands[ #commands + 1 ] = "stepRight"
		else
			if love.keyboard.isDown( self.rightKey ) then
				if ( self.turnMode == "EASY" ) then
					commands[ #commands + 1 ] = "easyRight"
				elseif ( self.turnMode == "NORMAL" ) then
					commands[ #commands + 1 ] = "normalRight"
				end
			end
		end
	end
	-- orbit planet
	if love.keyboard.isDown(self.orbitKey) then
		commands[ #commands + 1 ] = "orbit"
	end
	-- launch missile
	if self.state.launchMissile then
		commands[ #commands + 1 ] = "launchMissile"
		self.state.launchMissile = false
	end
	-- engage laser
	if self.state.engageLaser then
		commands[ #commands + 1 ] = "engageLaser"
		self.state.engageLaser = false
	end
	-- disengage laser
	if self.state.disengageLaser then
		commands[ #commands + 1 ] = "disengageLaser"
		self.state.disengageLaser = false
	end

	return commands
end

-- Respawn the player's ship
function player:respawn()
	self:error()
	self.theShip:respawn()
	self.theShip:setStatus("player")
end

--Passes the ship's body up the stack.
function player:getBody()
	self:error()
	return self.theShip:getBody()
end

-- the player's ship
function player:getShip()
	self:error()
	return self.theShip
end

-- the player's X position
function player:getX()
	self:error()
	return self.theShip:getX()
end

-- the player's Y position
function player:getY()
	self:error()
	return self.theShip:getY()
end

-- the points making up the player's polygon
function player:getPoints()
	self:error()
	return self.theShip:getPoints()
end
