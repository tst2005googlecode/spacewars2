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

game.lua

Currently, this is an example scenario to test rendering and movement.
--]]

require "subclass/class.lua"
require "util/camera.lua"
require "pause.lua"

-- Coordiante variables holding min x,y World coordinates
local minX = {}
local minY = {}
-- Coordinate variables holding max x,y World coordinates
local maxX = {}
local maxY = {}
-- Coordinate variables holding max x,y Screen coorinates
local screenX = {}
local screenY = {}
-- Box2D holder variables
local theWorld = {}
local theBody = {}
local theCircle = {}
local radius = {}
-- Camera control variables
local theCamera = {}
local currentX = {}
local currentY = {}
-- Current game state
local gameState = {}
game = class:new(...)

function game:init()
	--minimum and maximum valid X/Y coordinates
	minX = 0
	maxX = 1600
	screenX = love.graphics.getWidth()
	minY = 0
	maxY = 1600
	screenY = love.graphics.getHeight()
	--radius of our body
	radius = 10
	--declare the world
	theWorld = love.physics.newWorld(minX-100,minY-100,maxX+100,maxY+100)
	--set a new random seed
	math.randomseed(os.time())
	--reset the game
	game:reset()
	fps = 0
	--Test bodies to show the screen jitter is unique to the text
	--NOTE: Body collision is disabled by setting all masks to 1
	stillBody1 = love.physics.newBody(theWorld,600,600,1,0)
	stillCircle1 = love.physics.newCircleShape(stillBody1,0,0,radius)
	stillCircle1:setMask(1)
	stillBody2 = love.physics.newBody(theWorld,1000,600,1,0)
	stillCircle2 = love.physics.newCircleShape(stillBody2,0,0,radius)
	stillCircle2:setMask(1)
	stillBody3 = love.physics.newBody(theWorld,600,1000,1,0)
	stillCircle3 = love.physics.newCircleShape(stillBody3,0,0,radius)
	stillCircle3:setMask(1)
	stillBody4 = love.physics.newBody(theWorld,1000,1000,1,0)
	stillCircle4 = love.physics.newCircleShape(stillBody4,0,0,radius)
	stillCircle4:setMask(1)
end

function game:draw()
	-- Get the current camera position and apply it
	currentX, currentY = theCamera:adjust(minX,maxX,screenX,minY,maxY,screenY)
	love.graphics.translate(-currentX,-currentY)
	-- Change color to body color
	love.graphics.setColor(unpack(color["main"]))
	-- Draw the main movement body
	love.graphics.circle("fill", theBody:getX(), theBody:getY(), theCircle:getRadius(), 100)
	-- Draw the stationary test bodies
	love.graphics.circle("fill", stillBody1:getX(), stillBody1:getY(), stillCircle1:getRadius(), 100)
	love.graphics.circle("fill", stillBody2:getX(), stillBody2:getY(), stillCircle2:getRadius(), 100)
	love.graphics.circle("fill", stillBody3:getX(), stillBody3:getY(), stillCircle3:getRadius(), 100)
	love.graphics.circle("fill", stillBody4:getX(), stillBody4:getY(), stillCircle4:getRadius(), 100)

	-- Now draw the text on the screen
	-- NOTE: Text has "screen jitter"
	-- WARNING: TEXT DRAWING IS PROCESS INTENSIVE!  CURRENTLY DISABLED!
--	love.graphics.setFont(12)
--	love.graphics.setColor(unpack(color["text"]))
--	love.graphics.print("X Coordinate: " .. tostring(theBody:getX()), 50+currentX, 50+currentY)
--	love.graphics.print("Y Coordinate: " .. tostring(theBody:getY()), 50+currentX, 70+currentY)
--	love.graphics.print("Mouse X Coordinate: " .. tostring(love.mouse.getX() + currentX), 50+currentX, 90+currentY)
--	love.graphics.print("Mouse Y Coordinate: " .. tostring(love.mouse.getY() + currentY), 50+currentX, 110+currentY)
--	love.graphics.print("Frames per second: " .. tostring( fps ), 50-screenX, 130-screenY)
end

function game:update(dt)
	-- INITIAL state means we need to initialize a body for movement
	if gameState == "INITIAL" then
		game:reset()
	end
	fps = 1 / dt
	-- TRAVEL state means to the body is in motion and needs updating
	if gameState == "TRAVEL" then
		if(theBody:getX() > maxX) or (theBody:getX() < minX) or (theBody:getY() < minY) or (theBody:getY() > maxY) then
			gameState = "INITIAL" --restart in the center, do NOT update
		else
			theWorld:update(dt) --ONLY update if it won't crash engine
		end
	end
end

function game:keypressed(key)
	if key == "escape" then
--		state = menu:new()
		state = pause:new(game)
	end
end

function game:reset()
	--reset the position of the body and camera
	theBody = love.physics.newBody(theWorld,maxX/2,maxY/2,1,0)
	theCircle = love.physics.newCircleShape(theBody,0,0,radius)
	theCircle:setMask(1)
	theCamera = camera:new(theBody)
	currentX, currentY = theCamera:adjust(minX,maxX,screenX,minY,maxY,screenY)
	--come up with random X and Y velocities, and store them
	local xVelocity = math.random(-10,10) * 50
	local yVelocity = math.random(-10,10) * 50
	theBody:setLinearVelocity(xVelocity, yVelocity)
	gameState = "TRAVEL"
end
