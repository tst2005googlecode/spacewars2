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

-- these are configured from game config
local thrust
local left
local reverse
local right
local stopTurn
local stopThrust
local turn
local orbit

-- the following are dynamic parameters
local mass
local color
local startX
local startY
local startAngle

controlBag = class:new(...)

function controlBag:construct(thrustKey,leftKey,reverseKey,rightKey,stopTurnKey,stopThrustKey, orbitKey, zoomInKey, zoomOutKey, turnType, width, height, screen, ai, moons, debris, pMass)
	self.thrust = thrustKey
	self.left = leftKey
	self.reverse = reverseKey
	self.right = rightKey
	self.stopTurn = stopTurnKey
	self.stopThrust = stopThrustKey
	self.turn = turnType
	self.orbit = orbitKey
	self.zoomIn = zoomInKey
	self.zoomOut = zoomOutKey
	self.resWidth = width
	self.resHeight = height
	self.fullscreen = screen
	self.aiNum = ai
	self.moonNum = moons
	self.debrisNum = debris
	self.mass = pMass
end

function controlBag:getThrust()
	return self.thrust
end

function controlBag:setThrust(key)
	self.thrust = key
end

function controlBag:getLeft()
	return self.left
end

function controlBag:setLeft(key)
	self.left = key
end

function controlBag:getReverse()
	return self.reverse
end

function controlBag:setReverse(key)
	self.reverse = key
end

function controlBag:getRight()
	return self.right
end

function controlBag:setRight(key)
	self.right = key
end

function controlBag:getStopTurn()
	return self.stopTurn
end

function controlBag:setStopTurn(key)
	self.stopTurn = key
end

function controlBag:getStopThrust()
	return self.stopThrust
end

function controlBag:setStopThrust()
	self.stopThrust = key
end

function controlBag:getTurn()
	return self.turn
end

function controlBag:setTurn(aString)
	self.turn = aString
end

function controlBag:getOrbit()
	return self.orbit
end

function controlBag:setOrbit(key)
	self.orbit = key
end

function controlBag:getZoomIn()
	return self.zoomIn
end

function controlBag:setZoomIn(key)
	self.zoomIn = key
end

function controlBag:getZoomOut()
	return self.zoomOut
end

function controlBag:setZoomOut(key)
	self.zoomOut = key
end

function controlBag:getResWidth()
	return self.resWidth
end

function controlBag:setResWidth( width )
	self.resWidth = width
end

function controlBag:getResHeight()
	return self.resHeight
end

function controlBag:setResHeight( height )
	self.resHeight = height
end

function controlBag:isFullscreen()
	return self.fullscreen
end

function controlBag:setFullScreen( screen )
	self.fullscreen = screen
end

function controlBag:getAiNum()
	return self.aiNum
end

function controlBag:setAiNum( ai )
	self.aiNum = ai
end

function controlBag:getMoonNum()
	return self.moonNum
end

function controlBag:setMoonNum( moons )
	self.moonNum = moons
end

function controlBag:getDebrisNum()
	return self.debrisNum
end

function controlBag:setDebrisNum( debris )
	self.debrisNum = debris
end

--Aggregate methods

function controlBag:getAllControls()
	return self.thrust,self.left,self.reverse,self.right,self.stopTurn,self.stopThrust,self.orbit,self.zoomIn,self.zoomOut,self.turn
end

function controlBag:setAllControls(thrustKey,leftKey,reverseKey,rightKey,stopTurnKey,stopThrustKey,orbitKey,zoomInKey,zoomOutKey,turnType)
	self.thrust = thrustKey
	self.left = leftKey
	self.reverse = reverseKey
	self.right = rightKey
	self.stopTurn = stopTurnKey
	self.stopThrust = stopThrustKey
	self.turn = turnType
	self.orbit = orbitKey
	self.zoomIn = zoomInKey
	self.zoomOut = zoomOutKey
end

function controlBag:getAllResolution()
	return self.resWidth,self.resHeight,self.fullscreen
end

function controlBag:setAllResolution(width,height,screen)
	self.resWidth = width
	self.resHeight = height
	self.fullscreen = screen
end

function controlBag:getAllOptions()
	return self.aiNum,self.moonNum,self.debrisNum
end

function controlBag:setAllOptions(ai,moons,debris)
	self.aiNum = ai
	self.moonNum = moons
	self.debrisNum = debris
end

-- the following are dynamic parameters

function controlBag:getMass()
	return self.mass
end

function controlBag:setMass(number)
	self.mass = number
end

function controlBag:setStartPosition( pStartX, pStartY, pStartAngle )
	self.startX = pStartX
	self.startY = pStartY
	self.startAngle = pStartAngle
end
