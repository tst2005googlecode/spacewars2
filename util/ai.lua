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

ai.lua

This class implements an ai controller.
ai flies for 1000 update cycles before killing ignition.

WARNING: Uses global activeObjects table from game.lua!
--]]

require "subclass/class.lua"
require "util/functions.lua"

ai = class:new(...)

--[[
--Constructs and initializes the ai controller.
--
--Requirement 14
--]]
function ai:construct()
	self.cycles = 1000 --Fly for 1000 update cycles
	self.state = { respawn = false } --New ships don't need to respawn
	self.control = "A"
end
--[[
--Poll the ai for control input.
--Return the input to the ship that asked for it.
--
--Requirement 14
--]]
function ai:updateControls( shipState, dt )
	--Create a table to hold the commands
	local commands = {}
	--If dead, the AI should respawn instantly with a new ignition timer.
	if self.state.respawn then
		commands[ #commands + 1 ] = "respawn"
		self.state.respawn = false
		self.cycles = 1000
	--If the AI has time left, then it can still thrust
	elseif self.cycles > 0 then
		commands[ #commands + 1 ] = "thrust"
		self.cycles = self.cycles - dt * timeScale
	end

	--Finds the closes object, ignoring lasers and other ai
	self:closestObject(shipState)

	--Check distance of nearby objects
	if((self.objDistance < 1500) and (self.objType == "missile")) then
		--Will blow entire charge on a missile.
		commands[ #commands + 1 ] = "engageLaser"
	elseif ((self.objDistance < 500) and (self.objType == "playerShip")) then
		--Will only fire if it leaves reserve energy.
		if(shipState.data.laserCharge >= shipState.maxLaser*(3/4)) then
			commands[ #commands + 1 ] = "engageLaser"
		else
			commands[ #commands + 1 ] = "disengageLaser"
		end
	else
		commands[ #commands + 1 ] = "disengageLaser"
	end

	return commands
end

--[[
--Finds the closest enemy to this ai.
--Mutates properties to store the coordinate data needed for other functions.
--WARNING: Uses global activeObjects table from game.lua!
--
--Requirement 14
--]]
function ai:closestObject(aShip)
	self.objDistance = 999999
	local myX = aShip.body:getX()
	local myY = aShip.body:getY()
	for s,v in pairs(activeObjects) do
		local tempType = v:getType()
		--Ignore lasers and other ai
		if(not ((tempType == "laser") or (tempType == "aiShip"))) then
			local tempX = v.body:getX()
			local tempY = v.body:getY()
			local tempDist = pointDistance(myX,myY,tempX,tempY)
			if (tempDist < self.objDistance) then
				self.objDistance = tempDist
				self.objX = tempX
				self.objY = tempY
				self.objType = tempType
			end
		end
	end
end

--[[
--Gets the position the laser should aim at.
--]]
function ai:getLaserCoords()
	return self.objX,self.objY
end

--[[
--This function returns the controller of the ai
--]]
function ai:getControl()
	return self.control
end



--Old closestObject, that only checks for enemies!
--[[
function ai:closestEnemy(aShip)
	self.foeDistance = 999999
	local myX = aShip.body:getX()
	local myY = aShip.body:getY()
	for s,v in pairs(aShip.targets) do
		local tempX = v.body:getX()
		local tempY = v.body:getY()
		local tempDist = pointDistance(myX,myY,tempX,tempY)
		if (tempDist < self.foeDistance) then
			self.foeDistance = tempDist
			self.foeX = tempX
			self.foeY = tempY
		end
	end
end
--]]
