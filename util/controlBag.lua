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

controlBag.lua

This class is a data structure for holding the ship's controls.
	This includes keyboard controls and turning type.
Values can be returned individually, or in bulk.
--]]

require "subclass/class.lua"

local thrust
local left
local reverse
local right
local stopTurn
local stopThrust
local turn
local orbit
local mass

controlBag = class:new(...)

function controlBag:init(thrustKey,leftKey,reverseKey,rightKey,stopTurnKey,stopThrustKey,turnType, orbitKey, pMass)
	self.thrust = thrustKey
	self.left = leftKey
	self.reverse = reverseKey
	self.right = rightKey
	self.stopTurn = stopTurnKey
	self.stopThrust = stopThrustKey
	self.turn = turnType
    self.orbit = orbitKey
	self.mass = pMass
end

function controlBag:getThrust()
	return self.thrust
end

function controlBag:getLeft()
	return self.left
end

function controlBag:getReverse()
	return self.reverse
end

function controlBag:getRight()
	return self.right
end

function controlBag:getStopTurn()
	return self.stopTurn
end

function controlBag:getStopThrust()
	return self.stopThrust
end

function controlBag:getTurn()
	return self.turn
end

function controlBag:getOrbit()
	return self.orbit
end

function controlBag:getMass()
	return self.mass
end

function controlBag:getAllControls()
	return self.thrust,self.left,self.reverse,self.right,self.stopTurn,self.stopThrust,self.turn, self.orbit
end
