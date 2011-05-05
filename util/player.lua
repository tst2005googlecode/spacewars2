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

This class implements a player controller.
The controller is checked for mouse and keyboard input each cycle.
--]]

require "subclass/class.lua"
require "util/functions.lua"

local state

player = class:new(...)

--[[
--Constructs and initializes the player controller.
--]]
function player:construct( aCoordBag, shipConfig )
	--Assign the keyboard controls.
	self.thrustKey,self.leftKey,self.reverseKey,self.rightKey,self.stopTurnKey,self.stopThrustKey,self.orbitKey,self.assistKey,dummy1,dummy2,self.turnMode = shipConfig:getAllControls()
	--Initialize the state to all false.
	self.state = { stepLeft = false, stepRight = false, launchMissile = false, engageLaser = false, disengageLaser = false, respawn = false }
	self.control = "P"
end

--[[
--Checks the keyboard for input.
--Only used for the "STEP" style of turning (deimplemented?)
--
--Requirement 4.1
--]]
function player:keypressed( key )
	if self.turnMode == "STEP" then
		if key == theConfigBag:getLeft() then
			state.stepLeft = true
		elseif key == theConfigBag:getRight() then
			state.stepRight = true
		end
	end
	--if self.state.respawn and key == "return" then
		
	--end
end

--[[
--Checks the mouse for input.
--Left-click asks for the laser to start firing.
--Right-click asks for a missile to launch.
--
--Requirement 4.1
--]]
function player:mousepressed( x, y, button )
	if ( button == "r" ) then
		--Launch missile
		self.state.launchMissile = true
	end
	if ( button == "l" ) then
		--Engage laser
		self.state.engageLaser = true
	end
end

--[[
--Checks the mouse for input.
--Left-release asks for the laser to sto firing.
--
--Requirement 4.1
--]]
function player:mousereleased( x, y, button )
	if ( button == "l" ) then
		--Disengage laser
		self.state.disengageLaser = true
	end
end

--[[
--Checks for player input for thrust controls.
--This function is polled every cycle by the attached ship.
--
--Requirement 4.1
--]]
function player:updateControls( ownShip )
	local commands = {}
	self.ownShip = ownShip
	
	--If dead, the ship can respawn.
	--Players do not respawn instantly, they block until "return" is pressed.
	if self.state.respawn then
		if love.keyboard.isDown("return") then
			return { {"respawn" } }
		else return {}
		end
	end

	--Thrust controls
	if love.keyboard.isDown( self.stopThrustKey ) then
		--Stop linear velocity.
		commands[ #commands + 1 ] = { "stop" }
	else
		if love.keyboard.isDown( self.thrustKey ) then
			--Forward thrusters.
			commands[ #commands + 1 ] = { "thrust" }
		elseif love.keyboard.isDown( self.reverseKey ) then
			--Reverse thrusters.
			commands[ #commands + 1 ] = { "reverse" }
		end
	end
	--Rotation controls.
	if love.keyboard.isDown( self.stopTurnKey ) then
		--Stop angular velocity.
		commands[ #commands + 1 ] = { "stopRotation" }
	else
		--Left turn controls.
		if self.state.stepLeft then
			--Step turn left.
			commands[ #commands + 1 ] = { "stepLeft" }
		else
			if love.keyboard.isDown( self.leftKey ) then
				if ( self.turnMode == "EASY" ) then
					--Easy turn left.
					commands[ #commands + 1 ] = { "easyLeft" }
				elseif ( self.turnMode == "NORMAL" ) then
					--Normal turn left.
					commands[ #commands + 1 ] = { "normalLeft" }
				end
			end
		end
		--Right turn controls.
		if self.state.stepRight then
			--Step turn right.
			commands[ #commands + 1 ] = { "stepRight" }
		else
			if love.keyboard.isDown( self.rightKey ) then
				if ( self.turnMode == "EASY" ) then
					--Easy turn right.
					commands[ #commands + 1 ] = { "easyRight" }
				elseif ( self.turnMode == "NORMAL" ) then
					--Normal turn right.
					commands[ #commands + 1 ] = { "normalRight" }
				end
			end
		end
	end
	--Orbit control.
	if love.keyboard.isDown( self.orbitKey ) then
		commands[ #commands + 1 ] = { "orbit" }
	end
	-- locate nearest enemy missile and ship if targeting (similar to AI ability) ...
	-- this is not exactly accurate, as it targets where the object is, not where
	-- it will be
	if love.keyboard.isDown( self.assistKey ) then
		-- locating a target should only be needed when there is no current target
		-- or the current target is now inactive
		--if self.laserTarget == nil or self.laserTarget.isActive == false then
			--self.laserTarget = nil
			-- this will search for closest target from mouse cursor location
			-- probably not most useful ... leave in case used later
			--local x = theCamera:getX() + love.mouse.getX() / theCamera.zoom
			--local y = theCamera:getY() + love.mouse.getY() / theCamera.zoom
			-- this will search starting from ship's location
			local x = self.ownShip.body:getX()
			local y = self.ownShip.body:getY()
			local eMissile, eMissileDistance = nearest( x, y, missiles.objects, self )
			local eShip, eShipDistance = nearest( x, y, self.ownShip.targets )
			-- for now, only missiles will be considered
			if eMissileDistance < 8000 then--or eShipDistance < 8000 then
				--if eMissileDistance < eShipDistance then
					self.laserTarget = eMissile
				--else
				--	self.laserTarget = eShip
			--	end
			end
		--end
	end
	--On right-click, launch a missile.
	if self.state.launchMissile then
		if eMissileDistance or eShipDistance then
			if eMissileDistance < eShipDistance then
				commands[ #commands + 1 ] = { "launchMissile", eMissile }
			else
				commands[ #commands + 1 ] = { "launchMissile", eShip }
			end
		else -- missile will target closest enemy ... can be used to "find" the enemy
			commands[ #commands + 1 ] = { "launchMissile" }
		end
		self.state.launchMissile = false
	end
	--On left-click, engage lasers.
	if self.state.engageLaser then
		if love.keyboard.isDown( self.assistKey ) and ( eMissile ~= nil or eShip ~= nil ) then
			if eMissileDistance < eShipDistance then
				commands[ #commands + 1 ] = { "engageLaser", eMissile }
				self.laserTarget = eMissile
			-- currently, only missiles will be auto targeted
			--else
			--	commands[ #commands + 1 ] = { "engageLaser", eShip }
			--	self.laserTarget = eShip
			end
		else
			local coordinates = {}
			coordinates["x"] = love.mouse.getX()
			coordinates["y"] = love.mouse.getY()
			commands[ #commands + 1 ] = { "engageLaser" }
		end
		self.state.engageLaser = false
	end
	--On left-release, disengage lasers.
	if self.state.disengageLaser then
		commands[ #commands + 1 ] = { "disengageLaser" }
		self.state.disengageLaser = false
		self.laserTarget = nil
	end

	return commands
end

--[[
--This function returns the coordinates for the laser to point at.
--
--WARNING: Uses global theCamera from game.lua
--]]
function player:getLaserCoords()
	if self.laserTarget ~= nil then
		return self.laserTarget
	end
	return { x = ( theCamera:getX() + love.mouse.getX() / theCamera.zoom), y = ( theCamera:getY() + love.mouse.getY() / theCamera.zoom ) }
end

--[[
--This function returns the control string "P"
--]]
function player:getControl()
	return self.control
end


--WARNING: The following function are for old behavior, and should not be used.

--[[
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
--]]
