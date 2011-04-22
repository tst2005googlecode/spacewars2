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

options.lua
require "utils/controlBag.lua"

This class implements the options menu for Spacewars!II.
It contains links to the controls, configuration, and resolution views.
--]]

require "subclass/class.lua"
require "util/button.lua"

options = class:new()

--[[
--Both creates and initializes the main options view.
--
--Requirement 1.1.2, 1.2
--]]
function options:construct(aControlBag)
	--Initialize the buttons the user can press
	self.buttons = {controls = button:new("Controls", 400, 350),
					game = button:new("Game" , 400, 500)}
	--Store the configuration
	self.controlBag = aControlBag
end

--[[
--Draws the various buttons to the screen.
--]]
function options:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

--[[
--Updates the menu by highlighting a button the user has hovered over.
--]]
function options:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

--[[
--When the mouse is pressed, it checks if a button is under the cursor.
--If it's the Exit button, then close the program.
--Other buttons cause the appropriate view to be drawn.
--
--Requirements 1.2.1 to 1.2.3
--]]
function options:mousepressed(x,y,button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,button) then
			if n == "controls" then
				state = controls:new(self.controlBag) --Open controls
			elseif n == "game" then
				state = menu:new(self.controlBag) --Return to main menu
			end
		end
	end
end

--[[
--Checks for the escape key, if it is pressed, then return to main menu.
--]]
function options:keypressed(key)
	if key == "escape" then
		state = menu:new(self.controlBag) --Return to main menu
	end
end
