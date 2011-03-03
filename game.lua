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

main game control and framework
--]]

require "subclass/class.lua"
require "util/playerShip.lua"
require "util/solarMass.lua"
require "util/test.lua"
require "util/camera.lua"
require "util/coordBag.lua"
require "util/controlBag.lua"
require "pause.lua"

-- Coordinate variables holding min x,y World coordinates
local minX = 0
local minY = 0
-- Coordinate variables holding max x,y World coordinates
local maxX = 1600
local maxY = 1600
-- Coordinate variables holding max x,y Screen coordinates
local screenX = love.graphics.getWidth()
local screenY = love.graphics.getHeight()
-- Bag variables
local theCoordBag = coordBag:new(minX,maxX,screenX,minY,maxY,screenY)
local theControlBag = controlBag:new("w","a","s","d","q","e","NORMAL")
-- Box2D holder variables
local theWorld
local thePlayer
local gravity = 0
maxAngle = 0
-- Camera control variables
local theCamera
local currentX
local currentY
-- Current game state
local gameState
-- Misc stuff
local digits -- font for printing numbers
local frames = 0
local seconds = 0
local fps = 0

-- all drawable objects
local obj_draw = {}
local draw_count = 0
-- objects that will not change much
local solar_mass = {} -- Planet/moons
local numberOfMoons = 0
local orbital = {} -- stations, platforms, and other constructed orbitals
-- objects that will likely change frequently
local ship = {} -- list of capital ships (players, AIs)
local x_ship = {}
local ship_count = 0
local auto_obj = {} -- list of autonomous objects:  missiles, decoys, drones/fighters, probes, etc
local x_auto_obj = {}
local auto_draw_count = 0
local inert_obj = {} -- asteroids, junk, etc
local x_inert_obj = {}
local inert_draw_count = 0

-- all updatable objects
local obj_update = {}
local update_count = 0

game = class:new(...)

function game:init()
	-- constants
	maxAngle = math.pi * 2
	gravity = 0.0000000000667428 * 10000000

	-- for basic number output only
	digits = love.graphics.newImageFont( "images/digits.png", "1234567890.-" )
	love.graphics.setFont( digits )

	-- declare the world
	theWorld = love.physics.newWorld( minX - 100, minY - 100, maxX + 100, maxY + 100 )
	game:addUpdatable( theWorld )

	-- set a new random seed
	math.randomseed( os.time() )
	numberOfMoons = math.random( 0, 8 )

	-- generate planet and moons
	game:generateMasses( numberOfMoons )

	-- create player ship
	thePlayer = playerShip:new( theWorld, maxX/4, maxY/4, 0, theCoordBag, theControlBag )
	game:addDrawable( thePlayer )
	game:addUpdatable( thePlayer )

	-- reset the game
	game:reset()
end

function game:generateMasses( pNumberOfMoons )
	-- for now, always generate a planet
	local m = game:newMass( 0 )
	solar_mass[#solar_mass + 1] = solarMass:new( theWorld, m.x, m.y, m.mass, m.radius, 0, m.color )
	game:addDrawable( solar_mass[#solar_mass] )

	for i = 1, pNumberOfMoons do
		m = game:newMass( i )
		solar_mass[#solar_mass + 1] = solarMass:new( theWorld, m.x, m.y, m.mass, m.radius, m.orbit, m.color )
		game:addDrawable( solar_mass[#solar_mass] )
		game:addUpdatable( solar_mass[#solar_mass] )
		solar_mass[#solar_mass]["orbitRadius"] = m.orbitRadius
		solar_mass[#solar_mass]["orbitAngle"] = m.orbitAngle
		solar_mass[#solar_mass]["angularVelocity"] = m.angularVelocity
		solar_mass[#solar_mass]["originX"] = m.originX
		solar_mass[#solar_mass]["originY"] = m.originY
	end
end

function game:addDrawable( obj )
	draw_count = draw_count + 1
	obj_draw[draw_count] = obj
end

function game:addUpdatable( obj )
	update_count = update_count + 1
	obj_update[update_count] = obj
end

function game:newMass( index )
	local proto = {}
	
	if index == 0 then  -- 0 indicates generate a planet
		proto["orbit"] = 0
		proto["x"] = maxX / 2 -- center of game area
		proto["y"] = maxY / 2
		proto["radius"] = math.random( maxX / 20, maxX / 10 ) -- 5 to 10%?
		proto["mass"] = 10000
		proto["color"] = game:newColor()
	else  -- index > 0 are for moons ...
		-- moons must orbit outside 1.5x radius of planet
		local orbitRadius = solar_mass[1].massShape:getRadius() * 1.5 * index
		local orbitAngle = math.pi * math.random( 0, 1024 ) / 512
		local planet = solar_mass[1].massBody
		proto["orbit"] = index -- needs to be random
		proto["x"] = math.sin( orbitAngle ) * orbitRadius + planet:getX()
		proto["y"] = math.cos( orbitAngle ) * orbitRadius + planet:getY()
		proto["radius"] = math.random( 2, maxX / 200 ) -- 5 to 10% of planet?
		proto["mass"] = 100
		proto["color"] = game:newColor()
		proto["orbitRadius"] = orbitRadius
		proto["orbitAngle"] = orbitAngle
		-- w = v / r  ... where w is angular velocity, v is tangental velocity, and r is radius to origin
		proto["angularVelocity"] = ( ( ( planet:getMass() ^ 2) * gravity / ( proto.mass + planet:getMass() ) * orbitRadius ) ^ ( 1 / 2 ) ) / orbitRadius
		proto["originX"] = planet:getX()
		proto["originY"] = planet:getY()
	end
	
	-- v ~= ( (M^2)*G / (m + M)*r )^(1/2)
	

	return proto
end

function game:newColor()
	local color = {}
	color[1] = 128 + math.random( 0, 127 )
	color[2] = 128 + math.random( 0, 127 )
	color[3] = 128 + math.random( 0, 127 )
	color[4] = 255
	return color
end

function game:draw()
	-- Get the current camera position and apply it
	currentX, currentY = theCamera:adjust()
	love.graphics.translate( -currentX, -currentY )

	-- draw all objects
	for i, obj in ipairs( obj_draw ) do
		--if obj:draw then
			obj:draw()
		--end
	end

	local x = math.floor( currentX )
	local y = math.floor( currentY )

	if currentX - x >= 0.5 then
		x = x + 1
	end
	if currentY - y >= 0.5 then
		y = y + 1
	end

	-- Now draw the text on the screen
	-- NOTE: Text has "screen jitter"
	-- WARNING: TEXT DRAWING IS PROCESS INTENSIVE!  CURRENTLY DISABLED!
--	love.graphics.setFont(12)
--	love.graphics.setColor(unpack(color["text"]))
--	love.graphics.print("obj count: " .. #obj_draw, 50 + currentX, 50 + currentY)
--	love.graphics.print("Y Coordinate: " .. theBody:getY(), 50+currentX, 70+currentY)
--	love.graphics.print("Mouse X Coordinate: " .. (love.mouse.getX() + currentX), 50+currentX, 90+currentY)
--	love.graphics.print("Mouse Y Coordinate: " .. (love.mouse.getY() + currentY), 50+currentX, 110+currentY)
	love.graphics.print( fps, 5 + x, 5 + y )
end

function game:update( dt )
	seconds = seconds + dt
	frames = frames + 1
	if seconds > 1 then
		fps = frames
		frames = 0
		seconds = seconds - 1
	end

	-- update all objects
	for i, obj in ipairs( obj_update ) do
		--if obj:update then
			obj:update( dt )
		--end
	end
	--playerShip:update(dt)
	--theWorld:update(dt)
end

function game:keypressed(key)
	if key == "escape" then
--		state = menu:new()
		state = pause:new(game)
	end
end

--[[function game:reset()
	--reset the position of the body and camera
	theBody = love.physics.newBody(theWorld,maxX/2,maxY/2,1,0)
	theCircle = love.physics.newCircleShape(theBody,0,0,radius)
	theCircle:setMask(1)
	theCamera = camera:new(theBody)
	currentX, currentY = theCamera:adjust(minX,maxX,screenX,minY,maxY,screenY)
	--come up with random X and Y velocities, and store them
	local xVelocity = math.random(-10,10) * 50
	local yVelocity = math.random(-10,10) * 50
	if xVelocity == 0 then
		if yVelocity == 0 then
			xVelocity = 1000
		end
	end
	theBody:setLinearVelocity(xVelocity, yVelocity)
	gameState = "TRAVEL"
end]]--

function game:reset()
	-- reset the position of the ship
	theCamera = camera:new(theCoordBag,thePlayer:getBody())
	currentX, currentY = theCamera:adjust()
end

function game:destroy()
	obj_draw = {}
	draw_count = 0
	solar_mass = {}
	numberOfMoons = 0
	orbital = {}
	ship = {}
	x_ship = {}
	ship_count = 0
	auto_obj = {}
	x_auto_obj = {}
	auto_draw_count = 0
	inert_obj = {}
	x_inert_obj = {}
	inert_draw_count = 0
	obj_update = {}
	update_count = 0
end
