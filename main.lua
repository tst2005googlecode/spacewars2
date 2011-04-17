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

main.lua

This class is the required main class for the LOVE2D framework.
It initializes system constants.
It uses a polymorphic state variable.
The state is a view that is drawn, updated, and recieves user input.
--]]

require "menu.lua"
require "util/controlBag.lua"

sWidth, sHeight = 800, 600
config = {}
--Polymorphic variable holding the current view.
state = {}
--Master bag that holds the default system configuration.
local theControlBag = controlBag:new("w","a","s","d","q","e","r","1","2","EASY",800,600,"yes",9,4,100,100000)

--[[
--Initializing function that loads the LOVE2D framework.
--It also sets some constants and loads the configuration file.
--]]
function love.load()
	-- Explicitly set the directory before we even try to do anything!
	love.filesystem.setIdentity("Spacewars!II")
	-- Resource Constants
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

	--Checks for a configuration file, and if it exists, loads it.
	--WARNING: Lua does NOT guarantee order of table output.
	--Table must be manipulated directly, instead of using mutator functions!
	if(love.filesystem.exists("keybinding.conf")) then
		local theFile = love.filesystem.newFile("keybinding.conf")
		theFile:open("r")
		for line in theFile:lines() do
			equal = line:find("=")
			key = line:sub(1,equal-1)
			value = line:sub(equal+1)
			theControlBag[key] = value
		end
		theFile:close()
		theFile = nil
	end

	-- Setup the graphics engine
	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setMode(sWidth, sHeight, false, false, 0)

	-- Set the current view to the menu
	state = menu:new(theControlBag)
end

--[[
--Master function handling update cycles.
--It passes updating responsibilities to the current view.
--]]
function love.update(dt)
	if state.update then
		state:update(dt)
	end
end

--[[
--Master function handling drawing.
--It passes drawing responsibilities to the current view.
--]]
function love.draw()
	if state.draw then
		state:draw()
	end
end

--[[
--Master function handling keyboard presses.
--It passes input responsibilities to the current view.
--]]
function love.keypressed(key, unicode)
	if state.keypressed then
		state:keypressed(key, unicode)
	end
end

--[[
--Master function handling keyboard releases.
--It passes input responsibilities to the current view.
--]]
function love.keyreleased(key)
	if state.keyreleased then
		state:keyreleased(key)
	end
end

--[[
--Master function handling mouse presses.
--It passes input responsibilities to the current view.
--]]
function love.mousepressed(x, y, button)
	if state.mousepressed then
		state:mousepressed(x, y, button)
	end
end

--[[
--Master function handling mouse releases.
--It passes input responsibilities to the current view.
--]]
function love.mousereleased(x, y, button)
	if state.mousereleased then
		state:mousereleased(x, y, button)
	end
end

--[[
--Master function called while the engine is unloading.
--Used to save the game's configuration regardless of exit method.
--]]
function love.quit()
	local theFile = love.filesystem.newFile("keybinding.conf")
	theFile:open("w")
	--WARNING: Lua does NOT guarantee order of table output!
	for k,v in pairs(theControlBag) do
		if(type(v) ~= "table") then --Tables cannot be written. __baseclass is a table, and this throttles it.
			theFile:write(k .. "=" .. v .. "\r\n")
		end
	end
	theFile:close()
	theFile = nil
end

--[[
--Executes if LOVE ever loses focus.
--Leveraged by game.lua to pause the game on lost focus.
--]]
function love.focus()
	if state.focus then
		state:focus()
	end
end
