require "menu.lua"
require "util/controlBag.lua"

sWidth, sHeight = 800, 600
config = {}
state = {} --this is what gets called into action, whether that be the game, level editor, whatever...
local theControlBag = controlBag:new("w","a","s","d","q","e","r","1","2","EASY",800,600,false,9,4,100,100000)

function love.load()
	-- Set the directory before we even try to do anything!
	love.filesystem.setIdentity("Spacewars!II")
	--Resources
	color = {	background = {240,243,247},
				main = {63,193,245},
				text = {76,77,78},
				overlay = {255,255,255,235},
				ship = {255,255,255},
				ai = {255,96,96} }
	font = {	default = love.graphics.newFont(24),
				large = love.graphics.newFont(32),
				huge = love.graphics.newFont(72),
				small = love.graphics.newFont(22) }
	sound =	{	click = love.audio.newSource("media/click.ogg", "static"),}

	-- Variables
	size = 6     -- size of the grid
	audio = true -- whether audio should be on or off

	-- Creates a dummy file to force directory creation
	if (not love.filesystem.exists("dummy.txt")) then
		love.filesystem.write("dummy.txt", "")
	end

	-- Setup the graphics engine
	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setMode(sWidth, sHeight, false, false, 0)

	state = menu:new(theControlBag)
end

function love.update(dt)
	if state.update then
		state:update(dt)
	end
end

function love.draw()
	if state.draw then
		state:draw()
	end
end

function love.keypressed(key, unicode)
	if state.keypressed then
		state:keypressed(key, unicode)
	end
end

function love.keyreleased(key)
	if state.keyreleased then
		state:keyreleased(key)
	end
end

function love.mousepressed(x, y, button)
	if state.mousepressed then
		state:mousepressed(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	if state.mousereleased then
		state:mousereleased(x, y, button)
	end
end
