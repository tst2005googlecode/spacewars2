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

configHelp.lua

This class displays a configuration help screen for the user.
This help file explains what the config options do within the game.
--]]

require "subclass/class.lua"
require "util/button.lua"

configHelp = class:new(...)

--[[
--Construct the configuration help screen.
--Establishes all strings used on the screen.
--
--Requirement 1.2, 1.2.2
--]]
function configHelp:construct(aConfigBag)
	self.config = aConfigBag

	self.speed = "GameSpeed - Accelerates the speed of the simulation, between 100 and 500"
	self.ai = "NumberOfAi - The number of AI ships, between 1 and 9."
	self.aiRand = "RandomOpponents - If marked yes, the game spawns between 1 and NumberOfAi enemies."
	self.moon = "NumberOfMoons - The number of moons on the field, between 0 and 9."
	self.moonRand = "RandomMoons - If marked yes, the game spawns between 0 and NumberOfMoons moons."
	self.debris = "SolarDebris - Sets the soft limit for the amount of debris on the field."
	self.respawn = "PlayerRespawns - The number of ships you can lose before the game is over."

	self.title = "CONFIG HELP"
	self.titleWidth = font["large"]:getWidth(self.title)
	self.exit = button:new("Back",400,550)
end

--[[
--Draws all the help strings to the screen.
--Uses drawX and drawY to hold position, allowing easy resetting of the origin.
--
--Requirement 1.2, 1.2.2
--]]
function configHelp:draw()
	love.graphics.setFont(font["large"])
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.print(self.title,400-self.titleWidth/2,50)

	local drawX = 50
	local drawY = 120
	love.graphics.setFont(font["small"])
	love.graphics.print(self.speed,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.ai,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.aiRand,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.moon,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.moonRand,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.debris,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.respawn,drawX,drawY)
	drawY = drawY + 30

	self.exit:draw()
end

--[[
--Catches the escape key to return to the config menu.
--]]
function configHelp:keypressed(key)
	if(key == "escape") then
		self:back()
	end
end

--[[
--If the exit button is hovered over, highlight it.
--]]
function configHelp:update(dt)
	self.exit:update(dt)
end

--[[
--Catches the mouseclick, if it is on the exit button.
--]]
function configHelp:mousepressed(x,y,button)
	if self.exit:mousepressed(x,y,button) then
		self:back()
	end
end

--[[
--Return to the config menu.
--]]
function configHelp:back()
	state = playerconfig:new(self.config)
end
