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
require "util/player.lua"
require "util/ai.lua"
require "util/solarMass.lua"
require "util/ship.lua"
require "util/camera.lua"
require "util/coordBag.lua"
require "util/controlBag.lua"
require "util/objectBag.lua"
require "util/debris.lua"
require "util/radar.lua"
require "pause.lua"

-- global constants/variables
gravity = 0
lightSpeed = 0
maxAngle = 0
quarterCircle = 0
timeScale = 0     -- elapsed seconds, per second
worldScale = 0    -- 100 pixels = 1 meter
distanceScale = 0 -- virtual meters per pixel
forceScale = 0

-- global object framwork
solarMasses = {} -- Planet/moons
orbitals = {}    -- stations, platforms, and other constructed orbitals
ships = {}       -- list of capital ships, drones/fighters, etc (players, AIs)
missiles = {}    -- all the missiles
lasers = {}      -- all the laser beams
junk = {}        -- asteroids, debris, etc

types = {}       -- used by object framework

-- Coordinate variables holding min x,y World coordinates
local minX = 0
local minY = 0
-- Coordinate variables holding max x,y World coordinates
local maxX = 32768
local maxY = 32768
--local maxX = 16384
--local maxY = 16384
-- Coordinate variables holding max x,y Screen coordinates
local screenX = love.graphics.getWidth()
local screenY = love.graphics.getHeight()
-- Bag variables
local theCoordBag
theConfigBag = {}
-- Box2D holder variables
local theWorld
local thePlayer
-- Camera control variables
local theCamera
local currentX
local currentY
-- Radar, it must be drawn separately
local theRadar
local radarRadius = 8000
-- Current game state
local gameState
-- Misc stuff for HUD
local digits -- font for printing numbers
local frames = 0
local seconds = 0
local fps = 0
-- debug variables
local lastA = 0
local lowDt = 1
local highDt = 0
local lowA = 1000000000000000000000
local highA = -1000000000000000000000
lastAngle = 0

-- all updatable and drawable objects (except theWorld)
local activeObjects = {}

local needRespawn

game = class:new(...)

function game:construct( aControlBag, coord )
	-- set selected screen resolution
	--local modes = love.graphics.getModes()
	--love.graphics.setMode( modes[#modes].width, modes[#modes].height, true, false, 0 )
	--love.graphics.setMode( 1440, 900, true, false, 0 )

	-- constants and scalers
	maxAngle = math.pi * 2
	quarterCircle = math.pi / 2
	gravity = 0.0000000000667428
	lightSpeed = 299792458 -- meters per second
	worldScale = 100       -- 100 pixels = 1 meter
	distanceScale = 100000 -- meters per pixel (100 comes from world scale; see below)
	timeScale = 250        -- elapsed seconds, per second
	forceScale = timeScale ^ 2 / distanceScale / worldScale -- proportional to square of time scale

	-- font for basic number output only
	digits = love.graphics.newImageFont( "images/digits.png", "1234567890.-" )

	-- set up object framework
	solarMasses = objectBag:new( solarMass )
	--orbitals = objectBag:new( orbital )
	ships = objectBag:new( ship )
	missiles = objectBag:new( missile )
	lasers = objectBag:new( laser )
	junk = objectBag:new( debris )

	types.solarMass = "SOLARMASS"
	types.ship = "SHIP"
	types.debris = "DEBRIS"
	types.missile = "MISSILE"
	types.laser = "LASER"

	-- declare the world
	theWorld = love.physics.newWorld( minX - 100, minY - 100, maxX + 100, maxY + 100 )
	theWorld:setCallbacks(add,nil,nil,nil) -- collision, etc
	-- 100 pixels per meter!!
	theWorld:setMeter( worldScale ) -- Box2D can't hangle large spaces (should be 1 pixel = 100 km!)

	-- set a new random seed
	math.randomseed( os.time() )

	-- generate planet and moons
	game:generateMasses( math.random( 1, 4 ) + math.random( 1, 4 ) )

	-- configure controls and player ship
	theCoordBag = coordBag:new(minX,maxX,screenX,minY,maxY,screenY)
	theConfigBag = aControlBag
	theConfigBag["color"] = color["ship"]
	theConfigBag["shipType"] = "playerShip"
	theConfigBag:setStartPosition( game:randomeStartLocation() )
	thePlayer = player:new( theCoordBag, theConfigBag )
	local aShip = ships:getNew( theWorld, thePlayer, theCoordBag, theConfigBag )
	game:addActive( aShip )

	-- setup the camera and HUD elements
	theCamera = camera:new( theCoordBag, aShip.body )
	theRadar = radar:new( radarRadius, aShip.body )

	-- create all the debris
	for i = 1, 100 do
		local aDebris = debris:new( theWorld, theCoordBag )
		game:addActive( aDebris )
	end

	-- create enemy ship(s)
	theConfigBag = copyTable( theConfigBag )
	theConfigBag:setStartPosition( game:randomeStartLocation() )
	theConfigBag["color"] = color["ai"]
	theConfigBag["shipType"] = "aiShip"
	anAI = ai:new( theCoordBag, theConfigBag )
	aShip = ships:getNew( theWorld, anAI, theCoordBag, theConfigBag )
	game:addActive( aShip )

	-- The player doesn't need to respawn when the game starts!
	needRespawn = false
end

-- generate a randm start location within the game area
function game:randomeStartLocation()
	-- simple location ... may collide with other objects
	local startX = math.random( 0, maxX - 1 )
	local startY = math.random( 0, maxY - 1 )
	local startAngle = math.random() * maxAngle
	return startX, startY, startAngle
end

function game:generateMasses( pNumberOfMoons )
	-- for now, always generate a planet
	local m = game:newMass( 0 )
	local aSolarMass = solarMasses:getNew( theWorld, m.x, m.y, m.mass, m.radius, 0, m.color )

	for i = 1, pNumberOfMoons do
		m = game:newMass( i )
		aSolarMass = solarMasses:getNew( theWorld, m.x, m.y, m.mass, m.radius, m.orbit, m.color )
		aSolarMass["orbitRadius"] = m.orbitRadius
		aSolarMass["orbitAngle"] = m.orbitAngle
		aSolarMass["radialVelocity"] = m.radialVelocity
		aSolarMass["originX"] = m.originX
		aSolarMass["originY"] = m.originY
	end
end

function game:addActive( anObject )
	activeObjects[ #activeObjects + 1 ] = anObject
end

function game:removeActive( index )
	table.remove( activeObjects, index )
end

function game:newMass( index )
--	Notes about planets/moons ...
--	earth is ~6400 km radius and 5.9736 x 10^24 kg
--	planet like saturn is 60000 km radius and 5.6846 x 10^26 kg (600 pixels? 100 km per pixel)
--	planet like jupiter is 71000 km radius and 1.8986 x 10^27 kg
--	planet line neptune is 24750 km radius and 1.0243 x 10^26 kg
--	large moons range from 1500 to 2500+ km radius and 5 to 15 x 10^22 kg
--	400K km orbit to 2000k km orbits
--	small moons are irregular, and much less mass
--	120K km (2x planet) orbits out to far ranges

	local proto = {}
	if index == 0 then  -- 0 indicates generate the planet
		proto["orbit"] = 0
		proto["x"] = ( maxX - minX ) / 2 -- center of game area
		proto["y"] = ( maxY - minY ) / 2
		proto["radius"] = math.random( 250, 1000 ) -- for a gas giant (scaled by 100000 meters)
		proto["mass"] = math.random( 1, 25 ) * ( 10 ^ 26 )
		proto["color"] = game:newColor()
	else  -- index > 0 are for moons ...
		-- moons must orbit outside 2x radius of planet
		local planet = solarMasses.objects[1]
		if solarMasses == nil then game:error() end
		if solarMasses.objects == nil then game:error() end
		if solarMasses.count == 0 then game:error() end
		if planet == nil then game:error() end
		local orbitRadius = planet.massShape:getRadius() * 2 * index
		local orbitAngle = math.pi * math.random( 0, 1024 ) / 512
		proto["orbit"] = index -- needs to be random
		proto["x"] = math.sin( orbitAngle ) * orbitRadius + planet.body:getX()
		proto["y"] = math.cos( orbitAngle ) * orbitRadius + planet.body:getY()
		proto["radius"] = math.random( 10, 40 ) -- for a solid, round moon (scaled by 100000 meters)
		proto["mass"] = math.random( 1, 25 ) * ( 10 ^ 22 )
		proto["color"] = game:newColor()
		proto["orbitRadius"] = orbitRadius
		proto["orbitAngle"] = orbitAngle
		local radius = orbitRadius * distanceScale
		-- w = v / r  ... where w is angular velocity, v is tangental velocity, and r is radius to origin
		proto["radialVelocity"] = ( ( ( planet.body:getMass() ^ 2 ) * gravity /
								      ( ( proto.mass + planet.body:getMass() ) * radius )
								    ) ^ ( 1 / 2 )
								  ) / radius -- rad / s
		proto["originX"] = planet.body:getX()
		proto["originY"] = planet.body:getY()
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
	love.graphics.push() -- Allow quick return to default settings
	-- Get the current camera position and apply it
	currentX, currentY, screenZoom = theCamera:adjust()

	-- WARNING: Scale must come before translate, they are not commutative properties!
	love.graphics.scale( screenZoom )
	love.graphics.translate( -currentX, -currentY )

	-- draw all game objects
	for i, aSolarMass in ipairs( solarMasses.objects ) do
		aSolarMass:draw()
	end
	for i, anObject in ipairs( activeObjects ) do
		anObject:draw()
	end

	love.graphics.pop() -- Return to default settings to draw static objects

	-- render hud elements
	theRadar:draw( solarMasses.objects )
	theRadar:draw( activeObjects )
	love.graphics.setFont( digits )
	love.graphics.setColor(255,255,255)
	love.graphics.print( fps, 5, 5 )
	love.graphics.print( thePlayer.shipState.missileBank, 100, 5 )
--	love.graphics.print(debug,5,500)

	-- If the player ship has crashed, then tell the user what to do.
	if(needRespawn == true) then
		local text = "Your ship is destroyed, please press Enter to respawn!"
		love.graphics.setFont(font["default"])
		local textWidth = font["default"]:getWidth(text)
		local xPos = (screenX - textWidth)/2
		local yPos = 200
		love.graphics.print(text, xPos, yPos)
		love.graphics.setFont(font["small"])
	end
end

function game:update( dt )
	-- If the player needs to respawn, then freeze the game, otherwise, continue.
	if needRespawn == true then
		return
	end

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

	-- update planet positions first
	for i, aSolarMass in ipairs( solarMasses.objects ) do
		aSolarMass:update( dt )
	end

	-- for each active object, apply gravitation force from each solar mass
	for i, anObject in ipairs( activeObjects ) do
		if not anObject.isActive then
			game:removeActive( i )
		else
			for i, aSolarMass in ipairs( solarMasses.objects ) do
				applyGravity( aSolarMass, anObject )
			end
			anObject:update( dt )
		end
	end

	-- update the world separate from the other objects
	theWorld:update( dt )
end

function applyGravity( aSolarMass, anObject, dt )
	local difX = ( aSolarMass.body:getX() - anObject.body:getX() ) * distanceScale
	local difY = ( aSolarMass.body:getY() - anObject.body:getY() ) * distanceScale
	local dir = math.atan2( difY, difX )
	local dis2 = ( difX ^ 2 + difY ^ 2 ) -- ^ ( 1 / 2 )
	--local aG = gravity * ( solarMass.body:getMass() + object.body:getMass() ) /
	--					 ( dis2 * distanceScale )
	local fG = gravity * ( aSolarMass.body:getMass() * anObject.body:getMass() ) / dis2

	fG = fG * forceScale -- now scaled to pixels / s ^ 2
--[[
if lastA == 0 then lastA = fG end
if lastA > highA then highA = fG end
if lastA < lowA then lowA = fG end
--]]
	anObject.body:applyForce( math.cos( dir ) * fG , math.sin( dir ) * fG )
end

function game:keypressed( key, code )
	--Ship has crashed, so wait for input to respawn.
	if needRespawn == true then
		if key == "return" then
			needRespawn = false
			thePlayer.state.respawn = true
		end
	end
	--Escape key opens the pause menu.
	if key == "escape" then
		state = pause:new( game, theControlBag )
	else
		--Handle camera adjustments.
		theCamera:keypressed(key)
		thePlayer:keypressed(key)
	end
end

function game:mousepressed(x,y,button)
	thePlayer:mousepressed(x,y,button)
end

function game:destroy()
	thePlayer = {}
	theWorld = {}
	theCamera = {}
	theRadar = {}

	activeObjects = {}

	solarMasses = {}
	orbitals = {}
	ships = {}
	missiles = {}
	lasers = {}
	junk = {}
end

--Callback function to handle collisions based on object type.
function add( a, b, coll )
	if a.objectType == types.ship then
		shipCollide( a, b )
	elseif b.objectType == types.ship then
		shipCollide( b, a )
	elseif a.objectType == types.missile then
		missileCollide( a, b )
	elseif b.objectType == types.missile then
		missileCollide( b, a )
	elseif a.objectType == types.laser then
		laserCollide( a, b )
	elseif b.objectType == types.laser then
		laserCollide( b, a )
	elseif a.objectType == types.debris then
		debrisCollide( a, b )
	elseif b.objectType == types.debris then
		debrisCollide( b, a )
	end
end

--Handles player collisions. Set needRespawn = true whenever player ship is destroyed.
function shipCollide( a, b )
	if b.objectType == types.solarMass then
		a:destroy()
		if a.controller == thePlayer then
			needRespawn = true
		end
	elseif b.objectType == types.ship then
		a:destroy()
		b:destroy()
		needRespawn = true
	elseif b.objectType == types.debris then
		b:respawn()
	elseif b.objectType == types.laser then
		a:destroy()
		b:destroy()
	elseif b.objectType == types.missile then
		if b.data.owner ~= a.data.owner then
			a:destroy()
			b:destroy()
		end
	--[[elseif b.status == "DEAD" then
		a.status = "DEAD"
		needRespawn = true--]]
	end
end

-- missile collisions with other objects
function missileCollide( a, b )
	if b.objectType == types.solarMass then
		a:destroy()
	elseif b.objectType == types.debris then
		a:destroy()
		b:respawn()
	elseif b.objectType == types.laser then
		a:destroy()
		b:destroy()
	elseif b.objectType == types.missile then
		if a.owner ~= b.owner then
			a:destroy()
			b:destroy()
		end
	end
end

function laserCollide(a,b)
	if b.objectType == types.solarMass then
		a:destroy()
	--Lasers disipate on debris
	elseif b.objectType == types.debris then
		a:destroy()
	elseif b.objectType == types.laser then
		-- laser beams can't hurt each other
	end
end

function debrisCollide(a,b)
	if b.objectType == types.solarMass then
		a:respawn()
	elseif b.objectType == types.debris then
		a:respawn()
		b:respawn()
	end
end
