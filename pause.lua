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

pause.lua

This class implements a pause screen.
It takes the current state of the game and stores it temporarily.
If resume is selected, or ESC is pressed again, it restores the game state.
--]]

require "subclass/class.lua"
require "util/button.lua"
require "gameOver.lua"

pause = class:new(...)

--[[
--Both creates and initializes the pause view.
--]]
function pause:construct(aGame, aWidth, aControlBag, aScore)
	--Reveal the mouse cursor
	love.mouse.setVisible( true )
	--Store the game state and configuration
	self.temp = aGame
	self.tempControl = aControlBag
	self.score = aScore
	self.width = aWidth
	--Initialize the buttons the user can press.
	--Easier to write the score down as a button!
	self.buttons = {score = button:new("Score: " .. self.score, self.width/2, 100),
					resume = button:new("Resume", self.width/2, 250),
					quit = button:new("Quit", self.width/2, 350)}
end

--[[
--Updates the menu by highlighting a button the user has hovered over.
--]]
function pause:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

--[[
--When the mouse is pressed, it checks if a button is under the cursor.
--If the quit button is pressed, then return to the main menu.
--Otherwise, resume the game state.
--]]
function pause:mousepressed(x, y, button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,buttons) then
			if n == "resume" then
				love.mouse.setVisible( false ) -- hide the mouse cursor
				state = self.temp --Return to the game
			elseif n == "quit" then
				self.temp:destroy() --Release the game's storage
				state = gameOver:new(self.tempControl, self.score) --Return to main menu
			end
		end
	end
end

--[[
--Draws the various buttons to the screen.
--]]
function pause:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

--[[
--Checks for the escape key, if it is pressed, then return to the game.
--]]
function pause:keypressed(key)
	if key == "escape" then
		love.mouse.setVisible( false ) -- hide the mouse cursor
		state = self.temp --Return to the game
	end
end
