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

The main game view and framework for the simulated world.
It contains a number of ships, solar bodies, missiles, lasers, and debris.
It contains a camera that follows the player.
It contains a radar that shows the player's surroundings.
The game handles all collision tasks, using data provided by each object.
WARNING: Uses global sWidth and sHeight variables in main.lua
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
require "util/missile.lua"
require "util/laser.lua"
require "util/debris.lua"
require "util/radar.lua"
require "util/explosion.lua"
require "pause.lua"

--Declare constants/variables

--Global constants
gravity = 0
lightSpeed = 0
maxAngle = 0
quarterCircle = 0
timeScale = 0     -- elapsed seconds, per second
worldScale = 0    -- 100 pixels = 1 meter
distanceScale = 0 -- virtual meters per pixel
forceScale = 0    -- scale to apply to force values

--Global object framwork
solarMasses = {}  -- Planet/moons
orbitals = {}     -- stations, platforms, and other constructed orbitals
ships = {}        -- list of capital ships, drones/fighters, etc (players, AIs)
missiles = {}     -- all the missiles
lasers = {}       -- all the laser beams
junk = {}         -- asteroids, debris, etc
explosions = {}	  -- holds explosions for simulation

types = {}       -- used by object framework

--Coordinate variables holding min x,y World coordinates
local minX = 0
local minY = 0
--Coordinate variables holding max x,y World coordinates
local maxX = 32768
local maxY = 32768
--Coordinate variables holding max x,y Screen coordinates
--WARNING: These cannot be set until the screen mode has been set!
local screenX = 0
local screenY = 0
--Bag variables
local theCoordBag
local theConfigBag = {}
--Box2D holder variables
local theWorld
local thePlayer
local playerShip
--Camera control variables
theCamera = {}
local currentX
local currentY
--Radar, it must be drawn separately
local theRadar
local radarRadius = 8000
--Current game state
local gameState
--Misc stuff for HUD
local digits -- font for printing numbers
local frames = 0
local seconds = 0
local fps = 0
--Debug variables
local lastA = 0
local lowDt = 1
local highDt = 0
local lowA = 1000000000000000000000
local highA = -1000000000000000000000
lastAngle = 0
--All updatable and drawable objects (except theWorld)
activeObjects = {}
--Special effects are drawable/updatable, but not affected by gravity!
local activeEffects = {}
--Soft debris cap and total debris.
local maxDebris
activeDebris = 0
--Used to block the game when the player needs a respawn.
local needRespawn
--Used for missile guidance systems, send to created ships.
local playerShips = {}
local aiShips = {}
--Scoring and lives
local score = 0
local kills = 0
local currentLife = 0
local maxLives = 0
--Background settings
local background = {}
local quad = {}

game = class:new(...)

--[[
--Constructs the game, initializing all settings to configuration.
--
--Requirement 2.1-2.6
--]]
function game:construct( aConfigBag, coord )
	--Initialize some counter variables to 0
	activeDebris = 0
	score = 0
	kills = 0
	currentLife = 0
	maxLives = 0
	--Store theConfigBag
	theConfigBag = aConfigBag

	--Set selected screen resolution.
	--Fullscreen uses a string to determine, because booleans can't be written.
	if (theConfigBag:isFullscreen() == "yes") then
		--Set the graphics mode
		love.graphics.setMode(theConfigBag:getResWidth(),theConfigBag:getResHeight(),true,false,0)
	else
		love.graphics.setMode(theConfigBag:getResWidth(),theConfigBag:getResHeight(),false,false,0)
	end
	--Create the coordinate bag

	screenX = love.graphics.getWidth()
	screenY = love.graphics.getHeight()
	theCoordBag = coordBag:new(minX,maxX,screenX,minY,maxY,screenY)

	--local modes = love.graphics.getModes()
	--love.graphics.setMode( modes[#modes].width, modes[#modes].height, true, false, 0 )
	--love.graphics.setMode( 1440, 900, true, false, 0 )

	--Hide the mouse cursor and will draw cross-hairs
	love.mouse.setVisible( false )

	--Set constants and scalars
	maxAngle = math.pi * 2
	quarterCircle = math.pi / 2
	gravity = 0.0000000000667428
	worldScale = 100       --100 pixels = 1 meter
	distanceScale = 100000 --Meters per pixel (100 comes from world scale; see below)
	timeScale = theConfigBag:getSpeed()        --Elapsed seconds, per second
	forceScale = timeScale ^ 2 / distanceScale / worldScale --Proportional to square of time scale
	lightSpeed = 299792458 * timeScale / distanceScale --Pixels per second

	--Font for basic number output only
	digits = love.graphics.newImageFont( "images/digits.png", "1234567890.-AEFKLMS: " )

	--Set up object framework
	solarMasses = objectBag:new( solarMass )
	--orbitals = objectBag:new( orbital )
	ships = objectBag:new( ship )
	missiles = objectBag:new( missile )
	lasers = objectBag:new( laser )
	junk = objectBag:new( debris )
	explosions = objectBag:new( explosion )

	--Setup type constants
	types.solarMass = "SOLARMASS"
	types.ship = "SHIP"
	types.debris = "DEBRIS"
	types.missile = "MISSILE"
	types.laser = "LASER"
	types.explosion = "EXPLOSION"

	--Declare the world.
	theWorld = love.physics.newWorld( minX - 1000, minY - 1000, maxX + 1000, maxY + 1000 )
	--Set the collision callback to add.
	theWorld:setCallbacks(add,nil,nil,nil)
	--Set scale to 100 pixels per meter.
	theWorld:setMeter( worldScale ) -- Box2D can't hangle large spaces (should be 1 pixel = 100 km!)

	--Set a new random seed
	math.randomseed( os.time() )

	--Generate the solar masses (planets and moons)
	totalMoon = 0
	if(theConfigBag:getRandomMoon() == "yes") then
		totalMoon = math.random(0,theConfigBag:getMoonNum())
	else
		totalMoon = theConfigBag:getMoonNum()
	end
	game:generateMasses( totalMoon )

	--Configure and create the player's ship.
	theConfigBag["color"] = color["ship"]
	theConfigBag["shipType"] = "playerShip"
	theConfigBag:setStartPosition( game:randomeStartLocation() )
	thePlayer = player:new( theCoordBag, theConfigBag )
	local aShip = ships:getNew( theWorld, thePlayer, theCoordBag, theConfigBag )
	game:addActive( aShip )
	playerShips[1] = aShip
	playerShip = aShip

	--Setup the camera and HUD elements to focus on player's ship.
	theCamera = camera:new( theCoordBag, aShip.body, theConfigBag )
	theRadar = radar:new( radarRadius, aShip.body )

	--Create debris up to the softcap.
	activeDebris = 0
	maxDebris = theConfigBag:getDebrisNum()
	for i = 1, maxDebris do
		game:generateDebris("",0,0)
	end

	if(theConfigBag:getRandomAi() == "yes") then
		totalAi = math.random(1,theConfigBag:getAiNum())
	else
		totalAi = theConfigBag:getAiNum()
	end

	--Create enemy ships up to the cap.
	for i = 1, totalAi do
		theConfigBag = copyTable( theConfigBag )
		theConfigBag:setStartPosition( game:randomeStartLocation() )
		theConfigBag["color"] = color["ai"]
		theConfigBag["shipType"] = "aiShip"
		anAI = ai:new( theCoordBag, theConfigBag )
		aShip = ships:getNew( theWorld, anAI, theCoordBag, theConfigBag )
		aShip:addTargets(playerShips)
		game:addActive( aShip )
		aiShips[i] = aShip
	end

	--Engage player targeting system
	playerShips[1]:addTargets(aiShips)

	--The player doesn't need to respawn when the game starts.
	needRespawn = false
	currentLife = 1
	maxLives = theConfigBag:getLives() + 0 --Must add zero to coerce to int
	playerShips = {}
	aiShips = {}

	if(theConfigBag:getBackground() ~= "") then
		local fileString = "backgrounds/" .. theConfigBag:getBackground()
		if(love.filesystem.exists(fileString)) then
			background = love.graphics.newImage(fileString)
		else
			background = love.graphics.newImage("images/defaultbg.png")
		end
	else
		background = love.graphics.newImage("images/defaultbg.png")
	end
	background:setWrap("repeat","repeat")
	quad = love.graphics.newQuad(0,0,maxX,maxY,512,512)

end

--[[
--Generate a random start location within the game area.
--
--Requirement 2.3
--]]
function game:randomeStartLocation()
	--Simple location which may collide with other objects.
	local startX = math.random( 0, maxX - 1 )
	local startY = math.random( 0, maxY - 1 )
	local startAngle = math.random() * maxAngle
	return startX, startY, startAngle
end

--[[
--Used to fill the solarMasses table for this game.
--solarMass 0 is the planet, so it uses basic generation.
--solarMasses above 0 are moons, which have additional properties added to the object.
--These properties are used to enforce a static orbit.
--
--Requirement 2.4
--]]
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

--[[
--Adds an object to the update table.
--Only objects in this table will be updated and drawn to the screen.
--
--Requirement 2.7
--]]
function game:addActive( anObject )
	activeObjects[ #activeObjects + 1 ] = anObject
end

--[[
--Removes an object from the update table.
--
--Requirement 2.7
--]]
function game:removeActive( index )
	table.remove( activeObjects, index )
end

--[[
--Adds a special effect to the game.
--
--Requirement 11
--]]
function game:addEffect( anEffect )
	activeEffects[ #activeEffects + 1 ] = anEffect
end

--[[
--Removes a special effect from the game.
--
--Requirement 11
--]]
function game:removeEffect( index )
	table.remove( activeEffects, index )
end

--[[
--Generates a new solarMass with the neccessary parameters.
--solarMass 0 is the planet, so it uses basic generation.
--solarMasses above 0 are moons, which have additional properties added to the object.
--These properties are used to enforce a static orbit.
--
--Requirement 2.4
--]]
function game:newMass( index )
--[[
--	Notes about planets/moons ...
--	earth is ~6400 km radius and 5.9736 x 10^24 kg
--	planet like saturn is 60000 km radius and 5.6846 x 10^26 kg (600 pixels? 100 km per pixel)
--	planet like jupiter is 71000 km radius and 1.8986 x 10^27 kg
--	planet line neptune is 24750 km radius and 1.0243 x 10^26 kg
--	large moons range from 1500 to 2500+ km radius and 5 to 15 x 10^22 kg
--	400K km orbit to 2000k km orbits
--	small moons are irregular, and much less mass
--	120K km (2x planet) orbits out to far ranges
--]]

	local proto = {}
	if index == 0 then  --0 indicates generate the planet
		proto["orbit"] = 0
		proto["x"] = ( maxX - minX ) / 2 --Center of game area
		proto["y"] = ( maxY - minY ) / 2
		proto["radius"] = math.random( 250, 1000 ) --For a gas giant (scaled by 100000 meters)
		proto["mass"] = math.random( 1, 25 ) * ( 10 ^ 26 )
		proto["color"] = game:newColor()
	else  --Index > 0 are for moons ...
		--Moons must orbit outside 2x radius of planet
		local planet = solarMasses.objects[1]
		if solarMasses == nil then game:error() end
		if solarMasses.objects == nil then game:error() end
		if solarMasses.count == 0 then game:error() end
		if planet == nil then game:error() end
		--Establish an orbit radius and angle.
		local orbitRadius = planet.massShape:getRadius() * 2 * index
		local orbitAngle = math.pi * math.random( 0, 1024 ) / 512
		proto["orbit"] = index --Needs to be random
		--Set the initial X and Y coordinates, radius, and mass.
		proto["x"] = math.sin( orbitAngle ) * orbitRadius + planet.body:getX()
		proto["y"] = math.cos( orbitAngle ) * orbitRadius + planet.body:getY()
		proto["radius"] = math.random( 10, 40 ) --For a solid, round moon (scaled by 100000 meters)
		proto["mass"] = math.random( 1, 25 ) * ( 10 ^ 22 )
		--Set the color of the moon, and store the orbit radius and angle.
		proto["color"] = game:newColor()
		proto["orbitRadius"] = orbitRadius
		proto["orbitAngle"] = orbitAngle
		local radius = orbitRadius * distanceScale
		--w = v / r -
		--Where w is angular velocity, v is tangental velocity, and r is radius to origin
		proto["radialVelocity"] = ( ( ( planet.body:getMass() ^ 2 ) * gravity /
								      ( ( proto.mass + planet.body:getMass() ) * radius )
								    ) ^ ( 1 / 2 )
								  ) / radius -- rad / s
		--Establish the origin.
		proto["originX"] = planet.body:getX()
		proto["originY"] = planet.body:getY()
	end

	return proto
end

--[[
--Generate a new, random color.
--
--Requirement 2.4
--]]
function game:newColor()
	local color = {}
	color[1] = 64 + math.random( 0, 191 )
	color[2] = 64 + math.random( 0, 191 )
	color[3] = 64 + math.random( 0, 191 )
	color[4] = 255
	return color
end

--[[
--Draw the game view.
--Draws all objects in the update table.
--Translation and scaling are determined by the camera.
--solarMass is drawn separately because they aren't in the update table.
--The radar and HUD is drawn near the end, to ensure it's on top of all objects.
--The last thing drawn is the respawn message, if the playerShip is destroyed.
--
--Requirement 2.1-2.2, 2.6, 2.8
--]]
function game:draw()
	--Reset the color pallete
	love.graphics.setColor(255,255,255,255)
	love.graphics.push() -- Allow quick return to default settings
	--Get the current camera position and apply it
	currentX, currentY, screenZoom = theCamera:adjust()

	--WARNING: Scale must come before translate, they are not commutative properties!
	love.graphics.scale( screenZoom )
	love.graphics.translate( -currentX, -currentY )
	--Draw the background
	love.graphics.drawq(background,quad,0,0)

	--Draw all game objects
	for i, aSolarMass in ipairs( solarMasses.objects ) do
		aSolarMass:draw()
	end
	for i, anObject in ipairs( activeObjects ) do
		anObject:draw()
	end
	for i, anEffect in ipairs( activeEffects ) do
		anEffect:draw()
	end

	love.graphics.pop() --Return to default settings to draw static objects.

	--Render hud elements.
	theRadar:draw( solarMasses.objects )
	theRadar:draw( activeObjects )
	love.graphics.setFont( digits )
	love.graphics.setColor(255,255,255)
	--Draw ammo and armor to the right of the radar
	love.graphics.rectangle("line",130,0,45,80)
	love.graphics.print( "F: " .. fps, 135, 5)
	love.graphics.print( "K: " .. kills, 135, 15)
	love.graphics.print( "S: " .. string.format("%.1f", score), 135, 25)
	love.graphics.print( "L: " .. maxLives - currentLife, 135, 40)
	love.graphics.print( "A: " .. string.format("%.0f" , playerShip:getArmor()), 135, 50 )
	love.graphics.print( "M: " .. playerShip:getMissileBank(), 135, 60 )
	love.graphics.print( "E: " .. string.format("%.3f", playerShip:getLaserEnergy()), 135, 70)
	--Draw the game cursor on top of everything.
	game:drawCursor()
--	love.graphics.print(debug,5,500)


	--If the player ship has crashed, then tell the user what to do.
	if(needRespawn == true) then
		local text = ""
		if(currentLife > maxLives) then
			text = "You have run out of ships.  Press enter to continue!"
		else
			text = "Your ship is destroyed, please press Enter to respawn!"
		end
		love.graphics.setFont(font["default"])
		local textWidth = font["default"]:getWidth(text)
		local xPos = (screenX - textWidth)/2
		local yPos = 200
		love.graphics.print(text, xPos, yPos)
		love.graphics.setFont(font["small"])
	end
end

--[[
--Draw a crosshair in place of the mouse.
--]]
function game:drawCursor()
	love.graphics.setColor( 255, 64, 192 )
	local mouseX = love.mouse.getX()
	local mouseY = love.mouse.getY()
	love.graphics.line( mouseX, mouseY, mouseX + 8, mouseY + 8 )
	love.graphics.line( mouseX, mouseY, mouseX - 8, mouseY + 8 )
	love.graphics.line( mouseX, mouseY, mouseX + 8, mouseY - 8 )
	love.graphics.line( mouseX, mouseY, mouseX - 8, mouseY - 8 )
end

--[[
--Update all objects in the active object table.
--solarMass is updated separately because it is not in the table.
--If the player has been destroyed, then the function blocks until respawn.
--
--Requirement 2.7
--]]
function game:update( dt )
	--The world must be updated first.
	--Ensures new objects get a first draw BEFORE they start moving.
	theWorld:update( dt )

	--If the player needs to respawn, then freeze the game.
--	if needRespawn == true then
--		return
--	end

	lastA = 0
	seconds = seconds + dt
	frames = frames + 1
	if seconds > 1 then
		fps = frames
		frames = 0
		seconds = seconds - 1
--[[
lowDt = 1
highDt = 0
lowA = 10000000000000000000000000000
highA = -10000000000000000000000000000
--]]
	end
--[[
if dt < lowDt then lowDt = dt end
if dt > highDt then highDt = dt end
--]]

	--Update planet positions first
	for i, aSolarMass in ipairs( solarMasses.objects ) do
		aSolarMass:update( dt )
	end

	--For each active object, apply gravitation force from each solar mass
	for i, anObject in ipairs( activeObjects ) do
		if not anObject.isActive then
			--Since we're iterating the list, we remove inactives now as well.
			game:removeActive( i )
		else
			--Update active objects.
			for i, aSolarMass in ipairs( solarMasses.objects ) do
				applyGravity( aSolarMass, anObject )
			end
			anObject:update( dt )
		end
	end
	--For each active effect, update the particle system
	for i, anEffect in ipairs( activeEffects ) do
		if (not anEffect:getActive()) then
			game:removeEffect( i )
		else
			anEffect:update( dt )
		end
	end

	--Respawn debris if possible.
	--Done after active object cycle to prevent double references in the table.
	for i = activeDebris, maxDebris do
		game:generateDebris("border",0,0)
	end
end

--[[
--This function applies a solarMass's gravity to an updatable object.
--Other solarMass are excluded from ever being used in this function.
--
--Requirement 2.4
--]]
function applyGravity( aSolarMass, anObject, dt )
	--Determine the distance from the solarMass, as well as angle.
	local difX = ( aSolarMass.body:getX() - anObject.body:getX() ) * distanceScale
	local difY = ( aSolarMass.body:getY() - anObject.body:getY() ) * distanceScale
	local dir = math.atan2( difY, difX )
	local dis2 = ( difX ^ 2 + difY ^ 2 ) -- ^ ( 1 / 2 )
	--local aG = gravity * ( solarMass.body:getMass() + object.body:getMass() ) /
	--					 ( dis2 * distanceScale )

	--Determine the force of gravity to apply.
	local fG = gravity * ( aSolarMass.body:getMass() * anObject.body:getMass() ) / dis2

	fG = fG * forceScale -- now scaled to pixels / s ^ 2
--[[
if lastA == 0 then lastA = fG end
if lastA > highA then highA = fG end
if lastA < lowA then lowA = fG end
--]]
	anObject.body:applyForce( math.cos( dir ) * fG , math.sin( dir ) * fG )
end

--[[
--Generates a debris in the game world, with the given properties.
--X and Y should be 0, unless location = "ship", when it should be a ship's location.
--
--Requirement 2.5
--]]
function game:generateDebris( location, x, y )
	local aDebris = junk:getNew( theWorld, theCoordBag, location, x, y )
	game:addActive( aDebris )
	activeDebris = activeDebris + 1
end

--[[
--Polls the keyboard for input.
--If the ship has crashed, then it checks for the Return key to respawn.
--The escape key is used to open the pause menu.
--Other inputs are passed up to the Camera and Player controller.
--]]
function game:keypressed( key, code )
	--Ship has crashed, so wait for input to respawn.
	if needRespawn == true then
		if key == "return" then
			if(currentLife > maxLives) then
				--End game, return keeps next if block from executing
				self:destroy()
				state = gameOver:new(theConfigBag,score)
				return
			else
				needRespawn = false
				thePlayer.state.respawn = true
			end
		end
	end
	--Escape key opens the pause menu.
	if key == "escape" then
		state = pause:new( game, screenX, theConfigBag, score )
	else
		--Handle camera adjustments.
		theCamera:keypressed(key)
		thePlayer:keypressed(key)
	end
end

--[[
--Polls the mouse for input.
--Input is passed to the Player controller.
--]]
function game:mousepressed(x,y,button)
	thePlayer:mousepressed(x,y,button)
end

--[[
--Polls the mouse for input.
--Input is passed to the Player controller.
--]]
function game:mousereleased( x, y, button )
	thePlayer:mousereleased( x, y, button )
end

--[[
--If the game loses focus, then this opens the pause menu.
--]]
function game:focus()
	state = pause:new( game, sWidth, theConfigBag, self.score )
end

--[[
--This function handles what to do when the player dies.
--Could pass a parameter here for ship explosions?
--
--Requirement 12
--]]
function playerDeath()
	needRespawn = true
	currentLife = currentLife + 1
	score = kills/currentLife
end

--[[
--This function handles what to do when a player kills an ai.
--Could pass a parameter here for ship explosions?
--
--Requirement 12
--]]
function aiKill()
	kills = kills + 1
	score = kills/currentLife
end

--[[
--When the game ends, this clears out all objects and resets the graphic settings.
--WARNING: Uses global sWidth and sHeight variables in main.lua
--]]
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

	love.graphics.setMode(sWidth,sHeight,false,false,0)
end

--[[
--Callback function to handle collisions based on object type.
--Collisions are non-deterministic.
--Thus, collisions are determined twice for each type.
--	The needed object could be the first OR the second object in the pair.
--coll represents the collision generated, and is unused.
--WARNING: This comparrison order DOES matter, because collision functions are optimized.
--	Functions only check for collisions not handled in calls above it in the list!
--
--Requirement 2.7, 8.2, 9.2, 10, 11, 12
--]]
function add( a, b, coll )
	if a.objectType == types.ship then
		shipCollide( a, b, coll )
	elseif b.objectType == types.ship then
		shipCollide( b, a, coll )
	elseif a.objectType == types.missile then
		missileCollide( a, b, coll )
	elseif b.objectType == types.missile then
		missileCollide( b, a, coll )
	elseif a.objectType == types.laser then
		laserCollide( a, b, coll )
	elseif b.objectType == types.laser then
		laserCollide( b, a, coll )
	elseif a.objectType == types.debris then
		debrisCollide( a, b, coll )
	elseif b.objectType == types.debris then
		debrisCollide( b, a, coll )
	end
end

--[[
--Handles player and ai collisions.
--Set needRespawn = true whenever player ship is destroyed.
--
--Requirement 2.7, 8.2, 9.2, 10, 11, 12
--]]
function shipCollide( a, b, coll )
	if (not a.controller.state.respawn) then
	if b.objectType == types.solarMass then
		--Solar masses destroy ships instantly.
		a:destroy()
		if a.controller == thePlayer then
			playerDeath()
		end
	elseif b.objectType == types.ship then
		--Colliding ships destroy each other.
		a:destroy()
		b:destroy()
		if (a.controller == thePlayer) then
			aiKill()
			playerDeath()
		elseif (b.controller == thePlayer) then
			aiKill()
			playerDeath()
		end
	elseif b.objectType == types.debris then
		--Debris are destroyed and inflict damage on the ship.
		a.data.armor = a.data.armor - b.data.damage
		b:destroy()
		activeDebris = activeDebris - 1
		if(a.data.armor <= 0) then
			a:destroy()
			if(a.controller == thePlayer) then
				playerDeath()
			end
		end
	elseif b.objectType == types.laser then
		--Enemy lasers are destroyed and inflict damage on the ship.
		if b.data.owner ~= a.data.owner then
			a.data.armor = a.data.armor - b.data.damage
			if(a.data.armor <= 0) then
				a:destroy()
				if(a.controller == thePlayer) then
					playerDeath()
				else
					aiKill()
				end
			end
			b:destroy()
			--b.body:setPosition( coll:getPosition() )
		end
	elseif b.objectType == types.missile then
		--Enemy missiles are destroyed and inflict damage on the ship.
		if b.data.owner ~= a.data.owner then
			a.data.armor = a.data.armor - b.data.damage
			if(a.data.armor <= 0) then
				a:destroy()
				if(a.controller == thePlayer) then
					playerDeath()
				else
					aiKill()
				end
			end
			b:destroy()
		end
	--[[elseif b.status == "DEAD" then
		a.status = "DEAD"
		needRespawn = true--]]
	end
	end
end

--[[
--Missile collisions with other objects.
--Missiles can be destroyed by depleting their armor.
--
--Requirement 2.7, 8.2, 9.2, 10, 11
--]]
function missileCollide( a, b, coll )
	if b.objectType == types.solarMass then
		--solarMasses destroy missiles instantly.
		a:destroy()
	elseif b.objectType == types.debris then
		--Missiles are destroyed and inflict damage on debris.
		b.data.armor = b.data.armor - a.data.damage
		if(b.data.armor <= 0) then
			b:destroy()
			activeDebris = activeDebris - 1
		end
		a:destroy()
	elseif b.objectType == types.laser then
		--Lasers are destroyed and inflict damage on missiles.
		if a.data.owner ~= b.data.owner then
			a.data.armor = a.data.armor - b.data.damage
			if(a.data.armor <= 0) then
				a:destroy()
			end
			b:destroy()
			--b.body:setPosition( coll:getPosition() )
		end
	elseif b.objectType == types.missile then
		--Enemy missiles destroy each other.
		if a.data.owner ~= b.data.owner then
			a:destroy()
			b:destroy()
		end
	end
end

--[[
--Laser collisions with other objects.
--Lasers deplete armor, and are destroyed in almost all collisions.
--
--Requirement 2.7, 8.2, 10, 11
--]]
function laserCollide( a, b, coll )
	if b.objectType == types.solarMass then
		--solarMasses instantly destroy lasers.
		a:destroy()
		--a.body:setPosition( coll:getPosition() )
	elseif b.objectType == types.debris then
		--Lasers are destroyed and inflict damage on debris.
		b.data.armor = b.data.armor - a.data.damage
		if(b.data.armor <= 0) then
			b:destroy()
			activeDebris = activeDebris - 1
		end
		a:destroy()
		--a.body:setPosition( coll:getPosition() )
	elseif b.objectType == types.laser then
		--Laser beams can't hurt each other
	end
end

--[[
--Debris collisions with other objects.
--Debis can cause damage, and are destroyed when armor is depleted.
--
--Requirement 2.7, 10, 11
--]]
function debrisCollide(a,b,coll)
	if b.objectType == types.solarMass then
		--solarMasses instantly destroy debris.
		a:destroy()
	elseif b.objectType == types.debris then
		--Debris don't destroy each other anymore.
--		a:destroy()
--		b:destroy()
--		activeDebris = activeDebris - 2
	end
end
