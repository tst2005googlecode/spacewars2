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
	self.thrustTime = 0
	self.cruiseTime = 0
	self.state = { respawn = false } --New ships don't need to respawn
	self.control = "A"
	self.toHeading = nil
end

--[[
-- Poll the ai for control input.
-- Return the input to the ship that asked for it.
-- WARNING: Uses global missiles table from game.lua!
--
-- Requirement 14
--]]
function ai:updateControls( ownShip, dt )
	--Create a table to hold the commands
	local commands = {}
	
	--If dead, the AI should respawn instantly
	if self.state.respawn then
		commands[ #commands + 1 ] = { "respawn" }
		self.state.respawn = false
		return commands
	end

	--Find the closest enemy objects (with distance and angle), ignoring lasers and other ai, etc
	local x, y = ownShip.body:getPosition()
	local eMissile, eMissileDist, eMissileAngle = nearest( x, y, missiles.objects, self )
	local eShip, eShipDist, eShipAngle = nearest( x, y, ownShip.targets )

	if eShipDist < 8000 then
		self.toHeading = nil -- clear any previous heading info
		self.thrustTime = 0 -- clear thrust and cruise time
		self.cruisTime = 0
		-- launch missile
		commands[ #commands + 1 ] = { "launchMissile", eShip }
		--print( "ai: launch missile")
	else
		-- search for player
		if self.thrustTime <= 0 and self.cruiseTime <=0 then
			self.toHeading = math.random() * maxAngle
			self.thrustTime = 800
			self.cruiseTime = 12800
			--print( "ai: search for player " .. eShipDist )
		end
	end

	local velX, velY = ownShip.body:getLinearVelocity()
	local vel = hypotenuse( velX, velY )
	local vAngle = math.atan2( velY, velX )
	-- thrust for a time
	if self.thrustTime > 0 then
		-- if velocity into heading is not matching, apply thrust
		self.thrustTime = self.thrustTime - dt * timeScale
		--print( "ai: searching ... " .. eShipDist )
		if vel > 1000 then
			-- slow down if too fast ...
			commands[ #commands + 1 ] = { "reverseThrust", eShip }
			--print( "ai: reverse " .. velX .. " " .. velY )
		else
			commands[ #commands + 1 ] = { "thrust" }
		end
	else
		if self.cruiseTime > 0 then -- drift for a while
			self.cruiseTime = self.cruiseTime - dt * timeScale
		end

		--Check distance of nearby objects ...
		if ownShip.data.armor > 500 then
			if eShipDist > 1000 and eShipDist < 8000 then
				commands[ #commands + 1 ] = { "thrust" } -- toward
				self.toHeading = self.objAngle
				--print( "ai: head to player")
			end
		else
			if eShipDist < 4000 then
				commands[ #commands + 1 ] = { "thrust" } -- away
				self.toHeading = self.toHeading + math.pi
				if self.toHeading > maxAngle then -- normalize angle
					self.toHeading = self.toHeading - maxAngle
					--print( "ai: head away from player")
				end
			end
		end
	end
	--if((self.objDistance < 500) and (self.objType == "solarMass"))
	--	commands[ #commands + 1 ] = "thrust" -- away
	--end
	if eMissileDist < 1500 then
		-- Will expend entire charge on a missile.
		commands[ #commands + 1 ] = { "engageLaser" }
		self.laserTarget = eMissile
		--print( "ai: laser target missile")
	elseif eShipDist < 500 then
		--Will only fire if it leaves reserve energy.
		if ( ownShip.data.laserCharge >= ownShip.maxLaser / 2 ) then
			commands[ #commands + 1 ] =  { "engageLaser" }
			self.laserTarget = eShip
			--print( "ai: laser target player")
		else
			commands[ #commands + 1 ] = { "disengageLaser" }
		end
	else
		commands[ #commands + 1 ] = { "disengageLaser" }
	end
	-- turn to heading if needed
	if self.toHeading ~= nil then
		aDiff = self.toHeading - ownShip.body:getAngle() -- angle difference
		if math.abs( aDiff ) > ( maxAngle / 2 ) then
			if aDiff > 0 then -- normalize angle difference
				aDiff = aDiff - maxAngle
			else
				aDiff = aDiff + maxAngle
			end
		end
		if aDiff < -0.006136 or aDiff > 0.006136 then -- pi / 512 is close enough
			--print( "ai: change heading " .. aDiff )
			-- turn toward heading
			if aDiff > 0 then -- rotate right
				commands[ #commands + 1 ] = { "easyRight" }
			else -- rotate left
				commands[ #commands + 1 ] = { "easyLeft" }
			end
		end
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
function ai:closestObject( ownShip )
	self.objDistance = 999999
	local myX = ownShip.body:getX()
	local myY = ownShip.body:getY()
	for s,v in pairs(activeObjects) do
		local tempType = v:getType()
		-- Ignore lasers, non-player missiles, and other ai
		if ( not ( (tempType == "laser") or (tempType == "aiShip") or ( (tempType == "missile") 
				and v.owner.objType ~= "playerShip" ) ) ) then
			local tempX = v.body:getX()
			local tempY = v.body:getY()
			local tempDist = pointDistance(myX,myY,tempX,tempY)
			if (tempDist < self.objDistance) then
				self.objDistance = tempDist
				self.objX = tempX
				self.objY = tempY
				self.objType = tempType
				self.objAngle = pointAngle(myX,myY,tempX,tempY)
			end
		end
	end
end

--[[
--Gets the position the laser should aim at.
--]]
function ai:getLaserCoords()
	return self.laserTarget
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
