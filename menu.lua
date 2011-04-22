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

menu.lua

This class implements the main menu for Spacewars!II.
The menu contains buttons to start a new game and to change the configuration.
In the future, it might also contain a "How to Play" button.
--]]

require "game.lua"
require "highScore.lua"
require "options.lua"
require "help/gameHelp.lua"
require "subclass/class.lua"
require "util/button.lua"

menu = class:new(...)

--[[
--Both creates and initializes the main menu view.
--
--Requirement 1.1
--]]
function menu:construct(aControlBag)
	--Store the configuration for passing to other views.
	self.controlBag = aControlBag
	--Initialize the buttons the user can click.
	self.buttons =
	{
		new     = button:new("New Game",    400, 200),
		options = button:new("Options",     400, 275),
		score   = button:new("High Scores", 400, 350),
		help    = button:new("Help",        400, 425),
		exit    = button:new("Exit",        400, 500)
	}
end

--[[
--Updates the menu by highlighting a button the user has hovered over.
--]]
function menu:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

--[[
--When the mouse is pressed, it checks if a button is under the cursor.
--If it's the Exit button, then close the program.
--Other buttons cause the appropriate view to be drawn.
--
--Requremenents 1.1.1 to 1.1.5
--]]
function menu:mousepressed(x, y, button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,buttons) then
			if n == "new" then
				state = game:new(self.controlBag)
			elseif n == "options" then
				state = options:new(self.controlBag)
			elseif n == "score" then
				state = highScore:new(self.controlBag)
			elseif n == "help" then
				state = gameHelp:new(self.controlBag)
			elseif n == "exit" then
				love.event.push("q") --Quit the program
			end
		end
	end
end

--[[
--Draws the various buttons to the screen.
--]]
function menu:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

--[[
--Checks for the escape key, if it is pressed, then the program quits.
--]]
function menu:keypressed(key)
	if key == "escape" then
		love.event.push("q") --Quit the program
	end
end
