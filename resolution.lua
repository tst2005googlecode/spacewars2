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

resolution.lua

This class allows the user to change the resolution setting for the game.
It lists all supported fullscreen resolutions for the user's computer.
Upon clicking an option, it is immediately assigned and returns to graphics.lua.
--]]

require "subclass/class.lua"
require "util/button.lua"
require "util/controlBag.lua"

resolution = class:new(...)

--[[
--Constructs the resolution selection menu.
--
--Requirement 1.2.3
--]]
function resolution:construct(aConfigBag)
	self.config = aConfigBag

	self.resolutions = {}
	self.resolutions = love.graphics.getModes()

	self.resButtons = {}
	local drawX = 200
	local drawY = 150
	for n,b in ipairs(self.resolutions) do
		self.resButtons[#self.resButtons + 1] = button:new(b["width"] .. " x " .. b["height"], drawX, drawY)
		--Store the width and height with the button
		self.resButtons[#self.resButtons]["resWidth"] = b["width"]
		self.resButtons[#self.resButtons]["resHeight"] = b["height"]
		drawX = drawX + 400
		if(drawX > 700) then
			drawX = 200
			drawY = drawY + 50
		end
	end

	self.title = "CHANGE RESOLUTION"
	self.titleWidth = font["large"]:getWidth(self.title)
	self.exit = button:new("Back",400,550)
end

--[[
--Draws all the available resolutions to the screen.
--
--Requirement 1.2.3
--]]
function resolution:draw()
	love.graphics.setFont(font["large"])
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.print(self.title,400-self.titleWidth/2,50)
	for i,v in pairs(self.resButtons) do
		v:draw()
	end

end

--[[
--Highlights a button if it is hovered over.
--]]
function resolution:update(dt)
	for i,v in pairs(self.resButtons) do
		v:update(dt)
	end
end

--[[
--Captures the escape key to return to the graphics menu.
--]]
function resolution:keypressed(key)
	if(key == "escape") then
		self:back()
	end
end

--[[
--Captures mouse clicks.
--If it is over a resolution button, it assigns the resolution and returns.
--If it is over the Back button, it will return to the graphics menu.
--
--Requirement 1.2.3
--]]
function resolution:mousepressed(x,y,button)
	if self.exit:mousepressed(x,y,button) then
		self:back()
	else
		for n,b in pairs(self.resButtons) do
			if b:mousepressed(x,y,button) then
				self.config:setResWidth(b["resWidth"])
				self.config:setResHeight(b["resHeight"])
				self:back()
			end
		end
	end
end

--[[
--Returns to the graphics menu.
--]]
function resolution:back()
	state = graphics:new(self.config)
end
