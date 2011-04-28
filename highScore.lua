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

gameOver.lua

This class represents the view shown when the player views the high scores.
This is roughly the same as the gameOver view.
It simply lacks the game over text and new score input functionality.
--]]

require "subclass/class.lua"
require "util/button.lua"

highScore = class:new(...)

--[[
--This function constructs a new high score screen.
--It requires a configBag to send back to the menu, and can optionally take a score.
--
--Requirement 1.1.3, 1.2.4, 12
--]]
function highScore:construct(aConfigBag)
	self.configBag = aConfigBag
	self.width = sWidth/2
	self.col1 = 100
	self.col2 = 175
	self.col3 = 650
	self.start = 150
	self.space = 30
	self.exit = button:new("Back to Menu", self.width, 550)
end

--[[
--Write the high scores to the screen.
--
--Requirement 12
--]]
function highScore:draw()
	love.graphics.setColor(unpack(color["text"]))
	--Write the headers
	love.graphics.setFont(font["large"])
	stringWidth = font["large"]:getWidth("GAME OVER")
	love.graphics.print("GAME OVER", self.width - stringWidth/2, 10)
	love.graphics.setFont(font["default"])
	stringWidth = font["default"]:getWidth("High Scores")
	love.graphics.print("High Scores", self.width - stringWidth/2, 100)
	--Write the rank, the name, and the score, in "columns".
	love.graphics.setFont(font["small"])
	love.graphics.print("Rank", self.col1, self.start)
	love.graphics.print("Player Name", self.col2, self.start)
	love.graphics.print("Score", self.col3, self.start)
	--10 high scores.
	for i = 1,10 do
		love.graphics.print(i .. ".", self.col1, self.start + i * self.space)
		love.graphics.print("THE PLAYER NAME GOES RIGHT HERE EVERYONE", self.col2, self.start + i * self.space)
		love.graphics.print("SCORE",self.col3,self.start + i * self.space)
	end
	--Draw the exit button
	self.exit:draw()
end

--[[
--Capture the escape key.
--]]
function highScore:keypressed(key)
	if key == "escape" then
		self:back()
	end
end

--[[
--If the back button is clicked, then return to the menu.
--]]
function highScore:mousepressed(x, y, button)
	if self.exit:mousepressed(x, y, button) then
		self:back()
	end
end

--[[
--Highlight the button if it's being hovered over.
--]]
function highScore:update(dt)
	self.exit:update(dt)
end

--[[
--Return to the main menu.
--]]
function highScore:back()
	state = menu:new(self.configBag)
end
