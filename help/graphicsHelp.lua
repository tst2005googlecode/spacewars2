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

graphicsHelp.lua

This class displays a graphics help screen for the user.
This help file explains how the graphic change settings work.
--]]

require "subclass/class.lua"
require "util/button.lua"

graphicsHelp = class:new(...)

function graphicsHelp:construct(aConfigBag)
	self.config = aConfigBag

	self.changeRes1 = "Change Resolution"
	self.changeRes2 = "Clicking this will list all supported resolutions."
	self.changeRes3 = "Clicking any resolution will set it and return to the graphics menu."

	self.toggleFull1 = "Toggle Fullscreen"
	self.toggleFull2 = "Clicking this will toggle fullscreen mode off and on."

	self.changeBg1 = "Change Background"
	self.changeBg2 = "Clicking this will list all supported backgrounds."
	self.changeBg3 = "Backgrounds must be in .png format."
	self.changeBg4 = "Backgrounds are stored in the %appdata%/love/Spacewars!II/backgrounds directory"
	self.changeBg5 = "Clicking any background will set it and return to the graphics menu."

	self.title = "GRAPHICS HELP"
	self.titleWidth = font["large"]:getWidth(self.title)
	self.exit = button:new("Back",400,550)
end

function graphicsHelp:draw()
	love.graphics.setFont(font["large"])
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.print(self.title,400-self.titleWidth/2,50)

	local drawX = 50
	local drawY = 120
	love.graphics.setFont(font["small"])
	love.graphics.print(self.changeRes1,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.changeRes2,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.changeRes3,drawX,drawY)
	drawY = drawY + 60
	love.graphics.print(self.toggleFull1,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.toggleFull2,drawX,drawY)
	drawY = drawY + 60
	love.graphics.print(self.changeBg1,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.changeBg2,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.changeBg3,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.changeBg4,drawX,drawY)
	drawY = drawY + 30
	love.graphics.print(self.changeBg5,drawX,drawY)
	drawY = drawY + 30

	self.exit:draw()
end

function graphicsHelp:keypressed(key)
	if(key == "escape") then
		self:back()
	end
end

function graphicsHelp:update(dt)
	self.exit:update(dt)
end

function graphicsHelp:mousepressed(x,y,button)
	if self.exit:mousepressed(x,y,button) then
		self:back()
	end
end

function graphicsHelp:back()
	state = graphics:new(self.config)
end
