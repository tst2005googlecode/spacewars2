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

This class is a data structure for holding the game's configuration
	Keyboard controls.
	Game configuration.
	Window resolution.
Also used to set a mass and a start position for various bodies.
Values can be changed and retrieved individually, or in bulk.
An reference to this is passed to most construct/init functions.
--]]

require "subclass/class.lua"

controlBag = class:new(...)

--[[
--Constructs a bag to hold the configuration.
--WARNING: Lua permits sending nil parameters.
--For proper functionality, ALL properties must be sent to this function!
--]]
--This call can be complicated.  The proper call is: key,key,key,key,key,key,key,key,key,string,double,double,boolean,double,double,double,double
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

--[[
--Gets the key for thrusting.
--]]
function controlBag:getThrust()
	return self.thrust
end

--[[
--Sets the key for thrusting.
--]]
function controlBag:setThrust(key)
	self.thrust = key
end
--[[
--Gets the key for turning left.
--]]
function controlBag:getLeft()
	return self.left
end

--[[
--Sets the key for turning left.
--]]
function controlBag:setLeft(key)
	self.left = key
end

--[[
--Gets the key for reversing thrust.
--]]
function controlBag:getReverse()
	return self.reverse
end

--[[
--Sets the key for reversing.
--]]
function controlBag:setReverse(key)
	self.reverse = key
end

--[[
--Gets the key for turning right.
--]]
function controlBag:getRight()
	return self.right
end

--[[
--Sets the key for turning right.
--]]
function controlBag:setRight(key)
	self.right = key
end

--[[
--Gets the key to stop angular velocity.
--]]
function controlBag:getStopTurn()
	return self.stopTurn
end

--[[
--Sets the key to stop angular velocity.
--]]
function controlBag:setStopTurn(key)
	self.stopTurn = key
end

--[[
--Gets the key to stop linear velocity.
--]]
function controlBag:getStopThrust()
	return self.stopThrust
end

--[[
--Sets the key to stop linear velocity.
--]]
function controlBag:setStopThrust(key)
	self.stopThrust = key
end

--[[
--Gets the type of turn style to use.
--]]
function controlBag:getTurn()
	return self.turn
end

--[[
--Sets the type of turn style to use.
--]]
function controlBag:setTurn(aString)
	self.turn = aString
end

--[[
--Gets the key for orbiting the main solarMass.
--]]
function controlBag:getOrbit()
	return self.orbit
end

--[[
--Sets the key for orbiting the main solarMass.
--]]
function controlBag:setOrbit(key)
	self.orbit = key
end

--[[
--Gets the key for zooming the camera in.
--]]
function controlBag:getZoomIn()
	return self.zoomIn
end

--[[
--Sets the key for zooming the camera in.
--]]
function controlBag:setZoomIn(key)
	self.zoomIn = key
end

--[[
--Gets the key for zooming the camera out.
--]]
function controlBag:getZoomOut()
	return self.zoomOut
end

--[[
--Sets the key for zooming the camera out.
--]]
function controlBag:setZoomOut(key)
	self.zoomOut = key
end

--[[
--Gets the resolution's width.
--]]
function controlBag:getResWidth()
	return self.resWidth
end

--[[
--Sets the resolution's width.
--]]
function controlBag:setResWidth( width )
	self.resWidth = width
end

--[[
--Gets the resolution's height.
--]]
function controlBag:getResHeight()
	return self.resHeight
end

--[[
--Sets the resolution's height.
--]]
function controlBag:setResHeight( height )
	self.resHeight = height
end

--[[
--Gets the fullscreen status of the screen.
--]]
function controlBag:isFullscreen()
	return self.fullscreen
end

--[[
--Sets the fullscreen status of the screen.
--]]
function controlBag:setFullScreen( screen )
	self.fullscreen = screen
end

--[[
--Gets the number of ai to create.
--]]
function controlBag:getAiNum()
	return self.aiNum
end

--[[
--Sets the number of ai to create.
--]]
function controlBag:setAiNum( ai )
	self.aiNum = ai
end

--[[
--Gets the number of moons to create.
--]]
function controlBag:getMoonNum()
	return self.moonNum
end

--[[
--Sets the number of moons to create.
--]]
function controlBag:setMoonNum( moons )
	self.moonNum = moons
end

--[[
--Gets the soft limit for debris.
--The soft limit does not include debris from ship destruction.
--]]
function controlBag:getDebrisNum()
	return self.debrisNum
end

--[[
--Sets the soft limit for debris.
--The soft limit does not include debris from ship destruction.
--]]
function controlBag:setDebrisNum( debris )
	self.debrisNum = debris
end

--Aggregate methods

--[[
--Get all the control parameters in one call.
--]]
function controlBag:getAllControls()
	return self.thrust,self.left,self.reverse,self.right,self.stopTurn,self.stopThrust,self.orbit,self.zoomIn,self.zoomOut,self.turn
end

--[[
--Set all the control parameters in one call.
--]]
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

--[[
--Get all the resolution parameters in one call.
--]]
function controlBag:getAllResolution()
	return self.resWidth,self.resHeight,self.fullscreen
end

--[[
--Set all the resolution parameters in one call.
--]]
function controlBag:setAllResolution(width,height,screen)
	self.resWidth = width
	self.resHeight = height
	self.fullscreen = screen
end

--[[
--Get all the configuration parameters in one call.
--]]
function controlBag:getAllOptions()
	return self.aiNum,self.moonNum,self.debrisNum
end

--[[
--Set all the configuration parameters in one call.
--]]
function controlBag:setAllOptions(ai,moons,debris)
	self.aiNum = ai
	self.moonNum = moons
	self.debrisNum = debris
end


-- the following are dynamic parameters

--[[
--Get the mass to assign to a body.
--]]
function controlBag:getMass()
	return self.mass
end

--[[
--Set the mass to assign to a body.
--]]
function controlBag:setMass(number)
	self.mass = number
end

--[[
--Set the start position for a body.
--]]
function controlBag:setStartPosition( pStartX, pStartY, pStartAngle )
	self.startX = pStartX
	self.startY = pStartY
	self.startAngle = pStartAngle
end
