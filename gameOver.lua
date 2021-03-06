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
--
--Requirement 1.2.4, 12
--]]
function gameOver:construct(aConfigBag, score)
	self.configBag = aConfigBag
	--Define the buttons.
	self.width = sWidth/2
	self.continue = button:new("See High Scores", self.width, 500)
	self.skip = button:new("Skip", self.width, 550)
	--Check high scores!
	local i = 1
	self.nameEntry = false
	self.newScore = math.modf( score )
	while (i <= 10 and not self.nameEntry ) do
		if(self.newScore > highscoreTable[i]["score"]) then
			self.nameEntry = true
			self.placement = i
			self.rankString = "RANK: " .. self.placement
			self.rankLength = font["large"]:getWidth(self.rankString)
			self.namePrompt = "Enter a name for the high score table!"
			self.namePromptLength = font["large"]:getWidth(self.namePrompt)
			self.namePrompt2 = "Press enter when finished!"
			self.namePrompt2Length = font["large"]:getWidth(self.namePrompt2)
			self.nameString = ""
			self.continue = button:new("Add High Score", self.width, 500)
			break
		end
		i = i + 1
	end
	--Unhide the mouse
	love.mouse.setVisible(true)
	--Define the static strings and their lengths
	self.scoreString = "Final Score: " .. self.newScore .. " points!"
	self.scoreLength = font["large"]:getWidth(self.scoreString)
end

--[[
--This function draws the gameOver screen.
--If there is a new high score, then allow name entry.
--]]
function gameOver:draw()
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.setFont(font["large"])
	--Write things to the screen
	love.graphics.print(self.scoreString, self.width - self.scoreLength/2, 150)
	--The following should only be displayed if there is a new high score
	if(self.nameEntry == true) then
		love.graphics.print(self.rankString, self.width - self.rankLength/2, 225)
		love.graphics.print(self.namePrompt, self.width - self.namePromptLength/2,300)
		love.graphics.print(self.namePrompt2, self.width - self.namePrompt2Length/2,350)
		self.nameStringLength = font["large"]:getWidth(self.nameString)
		love.graphics.print(self.nameString, self.width - self.nameStringLength/2,400)
	end
	--Draw the buttons.
	self.continue:draw()
	self.skip:draw()
end

--[[
--Updates the buttons on the page, highlighting them if they are hovered over.
--]]
function gameOver:update(dt)
	self.continue:update(dt)
	self.skip:update(dt)
end

--[[
--Checks if mouse is pressed on a button and execute the appropriate function.
--]]
function gameOver:mousepressed(x,y,button)
	if(self.continue:mousepressed(x,y,button)) then
		--Submit high score
		self:highScore()
	elseif(self.skip:mousepressed(x,y,button)) then
		self:menu() --Return to main menu
	end
end

--[[
--Supports key entry by the player.
--Escape will skip to the main menu without submitting a score.
--Backspace will delete the last character in the nameString.
--Return will terminate the string and immediately submit it.
--All other keys that generate one character will be appended to the string.
--Keys that produce more than one character are IGNORED.
--
--Requirement 12
--]]
function gameOver:keypressed(key)
	if(key == "escape") then
		self:menu() --Return to main menu
	elseif(self.nameEntry) then
		if(key == "backspace") then
			--Delete a character if one is available
			if(self.nameString:len() > 0) then
				self.nameString = string.sub(self.nameString,1,self.nameString:len() - 1)
			end
		elseif(key == "return") then
			--Submit the score
			self:highScore()
		elseif(key:len() == 1) then
			--Append a character, if the key is one character long
			self.nameString = self.nameString .. key
		end
	end
end

--[[
--Return to the main menu.
--]]
function gameOver:menu()
	state = menu:new(self.configBag)
end

--[[
--Change to the high score table.
--
--Requirement 12
--]]
function gameOver:highScore()
	--Append to the high score table HERE, then load the view.
	if(self.nameEntry) then
		local i = 10
		while(i > self.placement) do
			highscoreTable[i]["name"] = highscoreTable[i-1]["name"]
			highscoreTable[i]["score"] = highscoreTable[i-1]["score"]
			i = i - 1
		end
		highscoreTable[self.placement]["name"] = self.nameString
		highscoreTable[self.placement]["score"] = self.newScore
	end
	state = highScore:new(self.configBag)
end
