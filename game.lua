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
require "util/camera.lua"
require "util/coordBag.lua"
require "util/controlBag.lua"
require "util/radar.lua"
require "pause.lua"

-- Coordinate variables holding min x,y World coordinates
local minX = 0
local minY = 0
-- Coordinate variables holding max x,y World coordinates
local maxX = 32768
local maxY = 32768
-- Coordinate variables holding max x,y Screen coordinates
local screenX = love.graphics.getWidth()
local screenY = love.graphics.getHeight()
-- Bag variables
local theCoordBag
local theConfigBag
-- Box2D holder variables
local theWorld
local thePlayer
gravity = 0
lightSpeed = 0
maxAngle = 0
quarterCircle = 0
timeScale = 0 -- elapsed seconds, per second
worldScale = 0 -- 100 pixels = 1 meter
distanceScale = 0 -- virtual meters per pixel
forceScale = 0
-- Camera control variables
local theCamera
local currentX
local currentY
-- Radar, it must be drawn separately
local theRadar
local radarRadius = 2000
-- Current game state
local gameState
-- Misc stuff
local digits -- font for printing numbers
local frames = 0
local seconds = 0
local fps = 0
local lastA = 0
local lowDt = 1
local highDt = 0
local lowA = 1000000000000000000000
local highA = -1000000000000000000000
lastAngle = 0

-- all drawable objects
local obj_draw = {}
local draw_count = 0
-- objects that will not change much
solarMasses = {} -- Planet/moons
local numberOfMoons = 0
orbitals = {} -- stations, platforms, and other constructed orbitals
-- objects that will likely change frequently
local ships = {} -- list of capital ships (players, AIs)
local x_ships = {}
local shipCount = 0
local autoObjs = {} -- list of autonomous objects:  missiles, decoys, drones/fighters, probes, etc
local x_autoObjs = {}
local autoObjCount = 0
local inertObjs = {} -- asteroids, junk, etc
local x_inertObjs = {}
local inertObjCount = 0

-- all updatable objects
local obj_update = {}
local update_count = 0

game = class:new(...)

function game:init( coord, control )
	-- set to full screen
	--local modes = love.graphics.getModes()
    --love.graphics.setMode( modes[#modes].width, modes[#modes].height, true, false, 0 )
    --love.graphics.setMode( 1440, 900, true, false, 0 )

	-- constants and scalers
	maxAngle = math.pi * 2
    quarterCircle = math.pi / 2
	gravity = 0.0000000000667428
    lightSpeed = 299792458 -- meters per second
    worldScale = 100 -- 100 pixels = 1 meter
	distanceScale = 100000 -- meters per pixel (100 comes from world scale; see below)
	timeScale = 250 -- elapsed seconds, per second
    forceScale = timeScale ^ 2 / distanceScale / worldScale -- proportional to square of time scale

	-- for basic number output only
	digits = love.graphics.newImageFont( "images/digits.png", "1234567890.-" )
	love.graphics.setFont( digits )

	-- declare the world
	theWorld = love.physics.newWorld( minX - 100, minY - 100, maxX + 100, maxY + 100 )
    -- 100 pixels per meter!!
	theWorld:setMeter( worldScale ) -- Box2D can't hangle large spaces (should be 1 pixel = 100 km!)
	game:addUpdatable( theWorld )

	-- set a new random seed
	math.randomseed( os.time() )
	numberOfMoons = math.random( 1, 4 ) + math.random( 1, 4 )

	-- generate planet and moons
	game:generateMasses( numberOfMoons )

	-- create controls and player ship
	theCoordBag = coordBag:new(minX,maxX,screenX,minY,maxY,screenY)
	theConfigBag = controlBag:new("w","a","s","d","q","e","r","NORMAL",100000)
	thePlayer = playerShip:new( theWorld, maxX/4, maxY/4, math.random() * maxAngle, theCoordBag, theConfigBag  )
	ships[#ships + 1] = thePlayer:getShip()
	shipCount = shipCount + 1
	game:addDrawable( thePlayer )
	game:addUpdatable( thePlayer )

	-- reset the camera and radar
	game:reset()
end

function game:generateMasses( pNumberOfMoons )
	-- for now, always generate a planet
	local m = game:newMass( 0 )
	solarMasses[#solarMasses + 1] = solarMass:new( theWorld, m.x, m.y, m.mass, m.radius, 0, m.color )
	game:addDrawable( solarMasses[#solarMasses] )

	for i = 1, pNumberOfMoons do
		m = game:newMass( i )
		solarMasses[#solarMasses + 1] = solarMass:new( theWorld, m.x, m.y, m.mass, m.radius, m.orbit, m.color )
		game:addDrawable( solarMasses[#solarMasses] )
		game:addUpdatable( solarMasses[#solarMasses] )
		solarMasses[#solarMasses]["orbitRadius"] = m.orbitRadius
		solarMasses[#solarMasses]["orbitAngle"] = m.orbitAngle
		solarMasses[#solarMasses]["radialVelocity"] = m.radialVelocity
		solarMasses[#solarMasses]["originX"] = m.originX
		solarMasses[#solarMasses]["originY"] = m.originY
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

--  earth is ~6400 km radius and 5.9736 x 10^24 kg
--  planet like saturn is 60000 km radius and 5.6846 x 10^26 kg (600 pixels? 100 km per pixel)
--  planet like jupiter is 71000 km radius and 1.8986 x 10^27 kg
--  planet line neptune is 24750 km radius and 1.0243 x 10^26 kg
--  large moons range from 1500 to 2500+ km radius and 5 to 15 x 10^22 kg
--    400K km orbit to 2000k km orbits
--  small moons are irregular, and much less mass
--    120K km (2x planet) orbits out to far ranges
	if index == 0 then  -- 0 indicates generate the planet
		proto["orbit"] = 0
		proto["x"] = maxX / 2 -- center of game area
		proto["y"] = maxY / 2
		proto["radius"] = math.random( 250, 1000 ) -- for a gas giant (scaled by 100000 meters)
		proto["mass"] = math.random( 1, 25 ) * ( 10 ^ 26 )
		proto["color"] = game:newColor()
	else  -- index > 0 are for moons ...
		-- moons must orbit outside 2x radius of planet
		local orbitRadius = solarMasses[1].massShape:getRadius() * 2 * index
		local orbitAngle = math.pi * math.random( 0, 1024 ) / 512
		local planet = solarMasses[1].body
		proto["orbit"] = index -- needs to be random
		proto["x"] = math.sin( orbitAngle ) * orbitRadius + planet:getX()
		proto["y"] = math.cos( orbitAngle ) * orbitRadius + planet:getY()
		proto["radius"] = math.random( 10, 40 ) -- for a solid, round moon (scaled by 100000 meters)
		proto["mass"] = math.random( 1, 25 ) * ( 10 ^ 22 )
		proto["color"] = game:newColor()
		proto["orbitRadius"] = orbitRadius
		proto["orbitAngle"] = orbitAngle
        local radius = orbitRadius * distanceScale
		-- w = v / r  ... where w is angular velocity, v is tangental velocity, and r is radius to origin
		proto["radialVelocity"] = ( ( ( planet:getMass() ^ 2 ) * gravity /
                                      ( ( proto.mass + planet:getMass() ) * radius )
                                    ) ^ ( 1 / 2 )
                                  ) / radius -- rad / s
 		proto["originX"] = planet:getX()
		proto["originY"] = planet:getY()
	end

	return proto
end

function game:newColor()
	local color = {}
	color[1] = 64 + math.random( 0, 191 )
	color[2] = 64 + math.random( 0, 191 )
	color[3] = 64 + math.random( 0, 191 )
	color[4] = 255
	return color
end

function game:draw()
	--Allow quick return to default settings
	--love.graphics.push()
	-- Get the current camera position and apply it
	currentX, currentY, screenZoom = theCamera:adjust()
	-- WARNING: Scale must come before translate, they are not commutative properties!
	love.graphics.scale( screenZoom )
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

	--Return to default settings to draw static objects
	--love.graphics.scale( 1 )

	-- Now draw the text on the screen
	-- NOTE: Text has "screen jitter"
	-- WARNING: TEXT DRAWING IS PROCESS INTENSIVE!  CURRENTLY DISABLED!
	love.graphics.setFont( digits )
--	love.graphics.setFont(12)
--	love.graphics.setColor(unpack(color["text"]))
--	love.graphics.print("obj count: " .. #obj_draw, 50 + currentX, 50 + currentY)
--	love.graphics.print("Y Coordinate: " .. theBody:getY(), 50+currentX, 70+currentY)
--	love.graphics.print("Mouse X Coordinate: " .. (love.mouse.getX() + currentX), 50+currentX, 90+currentY)
--	love.graphics.print("Mouse Y Coordinate: " .. (love.mouse.getY() + currentY), 50+currentX, 110+currentY)
--	love.graphics.print( thePlayer:getBody():getAngularVelocity(), 5 + x, 15 + y )
--	local velX, velY = thePlayer:getBody():getLinearVelocity()
--	love.graphics.print( lowDt, 5 + x, 25 + y )
--	love.graphics.print( highDt, 5 + x, 35 + y )
--	love.graphics.print( lastA, 5 + x, 45 + y )
--	love.graphics.print( thePlayer:getBody():getX(), 5 + x, 55 + y )
--	love.graphics.print( thePlayer:getBody():getY(), 5 + x, 65 + y )
--	love.graphics.print( thePlayer:getBody():getAngle(), 5 + x, 75 + y )
--    love.graphics.print( lastAngle, 5 + x, 75 + y )
--	love.graphics.print( lowA, 5 + x, 85 + y )
--	love.graphics.print( highA, 5 + x, 95 + y )

	--Return to default settings to draw static objects
	--love.graphics.pop()
	theRadar:draw(obj_draw)
	love.graphics.setFont( digits )
	love.graphics.print(fps, 5, 5)
end

function game:update( dt )
lastA = 0
	seconds = seconds + dt
	frames = frames + 1
	if seconds > 1 then
		fps = frames
		frames = 0
		seconds = seconds - 1
--[[lowDt = 1
highDt = 0
lowA = 10000000000000000000000000000
highA = -10000000000000000000000000000--]]
	end
--[[
if dt < lowDt then lowDt = dt end
if dt > highDt then highDt = dt end
--]]
	-- for each solar mass, apply gravitation force to each object
	for index, solarMass in ipairs( solarMasses ) do
		for i, orbital in ipairs( orbitals ) do
			applyGravity( solarMass, orbital )
		end
		for i, ship in ipairs( ships ) do
			applyGravity( solarMass, ship )
		end
		for i, autoObj in ipairs( autoObjs ) do
			applyGravity( solarMass, autoObj )
		end
		for i, inertObj in ipairs( inertObjs ) do
			applyGravity( solarMass, inertObj )
		end
	end

	-- update all objects
	for i, obj in ipairs( obj_update ) do
		--if obj:update then
			obj:update( dt )
		--end
	end
end

function applyGravity( solarMass, object, dt )
	local difX = ( solarMass.body:getX() - object.body:getX() ) * distanceScale
	local difY = ( solarMass.body:getY() - object.body:getY() ) * distanceScale
	local dir = math.atan2( difY, difX )
	local dis2 = ( difX ^ 2 + difY ^ 2 ) -- ^ ( 1 / 2 )
	--local aG = gravity * ( solarMass.body:getMass() + object.body:getMass() ) / 
    --                     ( dis2 * distanceScale )
	local fG = gravity * ( solarMass.body:getMass() * object.body:getMass() ) / dis2

    fG = fG * forceScale -- now scaled to pixels / s ^ 2
--[[
if lastA == 0 then lastA = fG end
if lastA > highA then highA = fG end
if lastA < lowA then lowA = fG end
--]]
	object:getBody():applyForce( math.cos( dir ) * fG , math.sin( dir ) * fG )
end

function game:keypressed( key, code )
	if key == "escape" then
		state = pause:new( game )
	else
		theCamera:keypressed(key)
		if theConfigBag:getTurn() == "STEP" then
			if key == theConfigBag:getLeft() then
				thePlayer:turnStepLeft()
			elseif key == theConfigBag:getRight() then
				thePlayer:turnStepRight()
			end
		end
	end
end

function game:reset()
	-- reset the position of the camera and set the radar
	theCamera = camera:new(theCoordBag,thePlayer:getBody())
	currentX, currentY = theCamera:adjust()
	theRadar = radar:new(radarRadius,thePlayer:getBody())
end

function game:destroy()
	obj_draw = {}
	draw_count = 0
	solarMasses = {}
	numberOfMoons = 0
	orbital = {}
	ship = {}
	x_ship = {}
	shipCount = 0
	auto_obj = {}
	x_auto_obj = {}
	auto_draw_count = 0
	inert_obj = {}
	x_inert_obj = {}
	inert_draw_count = 0
	obj_update = {}
	update_count = 0
end
