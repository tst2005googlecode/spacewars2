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

This class represents the view shown when the player quits or loses the game.
It will contain a high score list.
If there's a new high score, then it can provide some means of name entry.
--]]

require "subclass/class.lua"
require "util/button.lua"

gameOver = class:new(...)

--[[
--This function constructs a new game over screen.
--It requires a configBag to send back to the menu, and a score from the game.
--]]
function gameOver:construct(aConfigBag, score)
	love.mouse.setVisible(true)
	self.configBag = aConfigBag
	self.newScore = score
	self.width = sWidth/2
	self.col1 = 100
	self.col2 = 175
	self.col3 = 650
	self.start = 150
	self.space = 30
	self.exit = button:new("Back to Menu", self.width, 550)
end

--[[
--Write the Game Over text and high scores to the screen.
--]]
function gameOver:draw()
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
	for i = 1,10 do
		love.graphics.print(i .. ".", self.col1, self.start + i * self.space)
		love.graphics.print("THE PLAYER NAME GOES RIGHT HERE EVERYONE", self.col2, self.start + i * self.space)
		love.graphics.print("SCORE",self.col3,self.start + i * self.space)
	end
	self.exit:draw()
end

--[[
--Capture text input and the escape key.
--]]
function gameOver:keypressed(key)
	--Handle high score input

	if key == "escape" then
		self:back()
	end
end

--[[
--If the back button is clicked, then return to the menu.
--]]
function gameOver:mousepressed(x, y, button)
	if self.exit:mousepressed(x, y, button) then
		self:back()
	end
end

--[[
--Highlight the button if it's being hovered over.
--]]
function gameOver:update(dt)
	self.exit:update(dt)
end

--[[
--Return to the main menu.
--]]
function gameOver:back()
	state = menu:new(aConfigBag)
end
