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

graphics.lua

This class allows the user to change the graphic settings for the game.
This view shows the current settings, buttons will open menus for configuration.
	Done because the buttons could potentially overflow the screen.
Fullscreen IS toggled from this view.
--]]

require "subclass/class.lua"
require "util/button.lua"
require "util/controlBag.lua"
require "resolution.lua"

graphics = class:new(...)

--[[
--Construct the master graphics configuration view.
--Contains buttons to go to resolution and background menus.
--
--Requirement 1.2.3
--]]
function graphics:construct(aConfigBag)
	self.config = aConfigBag
	self.graphic = {}
	self.graphic["width"] = self.config:getResWidth()
	self.graphic["height"] = self.config:getResHeight()
	self.graphic["fullscreen"] = self.config:isFullscreen()
	self.graphic["background"] = self.config:getBackground()

	self.buttons =
	{
		resolution = button:new("Change Resolution",400,350),
		fullscreen = button:new("Toggle Fullscreen",400,400),
		background = button:new("Change Background",400,450),
		exit = button:new("Back",400,500)
	}
end

--[[
--Draw the information and buttons to the screen.
--
--Requirement 1.2.3
--]]
function graphics:draw()
	love.graphics.setFont(font["large"])
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.print("Current resolution: " .. self.graphic["width"] .. " x " .. self.graphic["height"],200,50)
	love.graphics.print("Fullscreen enabled: " .. self.graphic["fullscreen"],200,100)
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

--[[
--Captures the escape key and returns to the options menu.
--]]
function graphics:keypressed(key)
	if(key == "escape") then
		self:back()
	end
end

--[[
--Captures mouseclicks.
--Clicking Change Resolution/Background will open the respective view.
--Clicking Toggle Fullscreen will immediately change the fullscreen setting.
--The view can also be exited using the Back button.
--
--Requirement 1.2.3
--]]
function graphics:mousepressed(x,y,button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,button) then
			if(n == "resolution") then
				state = resolution:new(self.config)
			elseif(n == "fullscreen") then
				if(self.graphic["fullscreen"] == "yes") then
					self.graphic["fullscreen"] = "no"
					self.config:setFullscreen("no")
				else
					self.graphic["fullscreen"] = "yes"
					self.config:setFullscreen("yes")
				end
			elseif(n == "background") then
			elseif(n == "exit") then
				self:back()
			end
		end
	end
end

--[[
--Highlights a button if it has been hovered over.
--]]
function graphics:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

--[[
--Returns to the options menu.
--]]
function graphics:back()
	state = options:new(self.config)
end
