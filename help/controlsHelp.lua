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

controlsHelp.lua

This class displays a controls help screen for the user.
This help file explains what the controls do within the game.
--]]

require "subclass/class.lua"
require "util/button.lua"

controlsHelp = class:new(...)

--[[
--Construct the controls help screen.
--Establishes all strings used on the screen.
--
--Requirement 1.2, 1.2.1
--]]
function controlsHelp:construct(aConfigBag)
	self.config = aConfigBag

	self.thrust = "Thrust - Accelerates your ship in the direction you're facing."
	self.brake = "Brake - Slows your ship down at 1/2 thrust, opposite the direction you're FACING."
	self.left = "Left - Turns your ship to the left."
	self.right = "Right - Turns your ship to the right."
	self.stopTurn = "StopTurn - Stops your turning if you are using NORMAL mode."
	self.stopThrust = "StopThrust - Slows your ship down at 1/3 thrust, opposite the direction you're MOVING."
	self.orbit = "Orbit - Allows your ship to orbit the planet, if it's close enough."
	self.target = "TargetAssist - Points your lasers in the direction of the nearest AI or missile!"
	self.zoomIn = "ZoomIn - Zoom in on the action."
	self.zoomOut = "ZoomOut - Zoom out of the action."
	self.turn = "TurnType - Two different modes."
	self.turnEasy = "EASY - Turns at a constant speed for as long as you hold the turn button."
	self.turnNormal = "NORMAL - Accelerate turning while the button is held. You keep turning after release!"

	self.title = "CONTROLS HELP"
	self.titleWidth = font["large"]:getWidth(self.title)
	self.exit = button:new("Back",400,550)
end

--[[
--Draws all the help strings to the screen.
--Uses drawX and drawY to hold position, allowing easy resetting of the origin.
--
--Requirement 1.2, 1.2.1
--]]
function controlsHelp:draw()
	love.graphics.setFont(font["large"])
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.print(self.title,400-self.titleWidth/2,50)

	local drawX = 50
	local drawY = 120
	love.graphics.setFont(font["small"])
	love.graphics.print(self.thrust,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.brake,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.left,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.right,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.stopTurn,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.stopThrust,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.orbit,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.target,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.zoomIn,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.zoomOut,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.turn,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.turnEasy,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.turnNormal,drawX,drawY)
	drawY = drawY + 30

	self.exit:draw()
end

--[[
--Catches the escape key to return to the controls menu.
--]]
function controlsHelp:keypressed(key)
	if(key == "escape") then
		self:back()
	end
end

--[[
--If the exit button is hovered over, highlight it.
--]]
function controlsHelp:update(dt)
	self.exit:update(dt)
end

--[[
--Catches the mouseclick, if it is on the exit button.
--]]
function controlsHelp:mousepressed(x,y,button)
	if self.exit:mousepressed(x,y,button) then
		self:back()
	end
end

--[[
--Return to the controls menu.
--]]
function controlsHelp:back()
	state = controls:new(self.config)
end
