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
--]]

require "subclass/class.lua"
require "pause.lua"

game = class:new(...)

function game:init()
	--minimum and maximum valid X/Y coordinates
	minX = 0
	maxX = 1600
	minY = 0
	maxY = 1200
	--default starting position for the camera, smack in the middle for now
	startX = (love.graphics.getWidth() - maxX)/2
	startY = (love.graphics.getHeight() - maxY)/2
	--radius of our body
	radius = 10
	--the parameters for our world, note it must be larger than VALID coordinates
	theWorld = love.physics.newWorld(minX-100,minY-100,maxX+100,maxY+100)
	--Variables for the Body and it's accompanying CircleShape
	theBody = {}
	theCircle = {}
	--variables holding current camera position and body velocity
	screenX = {}
	screenY = {}
	xVelocity = {}
	yVelocity = {}
	gameState = {}
	--Variable for the current state of the simulation, starts in INITIAL mode
	game:reset()
	fps = 0
end

function game:draw()
	game:adjustCamera()
	love.graphics.translate(screenX,screenY)
	love.graphics.setColor(unpack(color["main"]))
	love.graphics.circle("fill", theBody:getX(), theBody:getY(), theCircle:getRadius(), 100)
	love.graphics.setFont(12)
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.print("X Coordinate: " .. tostring(theBody:getX()), 50-screenX, 50-screenY)
	love.graphics.print("Y Coordinate: " .. tostring(theBody:getY()), 50-screenX, 70-screenY)
	love.graphics.print("Mouse X Coordinate: " .. tostring(love.mouse.getX() - screenX), 50-screenX, 90-screenY)
	love.graphics.print("Mouse Y Coordinate: " .. tostring(love.mouse.getY() - screenY), 50-screenX, 110-screenY)
	love.graphics.print("Frames per second: " .. tostring( fps ), 50-screenX, 130-screenY)
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
			theWorld:update(1) --ONLY update if it won't crash engine
		end
	end
end

function game:keypressed(key)
	if key == "escape" then
--		state = menu:new()
		state = pause:new(game)
	end
end

function game:adjustCamera()
	--If theBody is within 20% of the edge, the camera moves with it
	--If there is only 20% of the board left, the camera stops moving
	--theBody moves in two directions: two pans can occur at once
	--Each check is done separately, rather than doing if/then/else
	if(theBody:getX() + screenX > love.graphics.getWidth() * 0.8) then
		if(theBody:getX() < maxX - love.graphics.getWidth() * 0.2) then
			screenX = screenX - math.abs(xVelocity)
		end
	end
	if (theBody:getX() + screenX < love.graphics.getWidth() * 0.2) then
		if(theBody:getX() > love.graphics.getWidth() * 0.2) then
			screenX = screenX + math.abs(xVelocity)
		end
	end
	if (theBody:getY() + screenY > love.graphics.getHeight() * 0.8) then
		if(theBody:getY() < maxY - love.graphics.getHeight() * 0.2) then
			screenY = screenY - math.abs(yVelocity)
		end
	end
	if (theBody:getY() + screenY < love.graphics.getHeight() * 0.2) then
		if(theBody:getY() > love.graphics.getHeight() * 0.2) then
			screenY = screenY + math.abs(yVelocity)
		end
	end
end

function game:reset()
	--reset the position of the body and camera
	theBody = love.physics.newBody(theWorld,800,600,1,0)
	theCircle = love.physics.newCircleShape(theBody,0,0,radius)
	screenX = startX
	screenY = startY
	--come up with random X and Y velocities, and store them for the camera
	xVelocity = math.random(-10,10)
	yVelocity = math.random(-10,10)
	theBody:setLinearVelocity(xVelocity, yVelocity)
	gameState = "TRAVEL"
end
