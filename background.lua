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

background.lua

This class allows the user to change the background used in the game.
It lists all files is %appdata%\Love\Spacewars!II\backgrounds directory.
Upon clicking an option, it is immediately assigned and returns to graphics.lua.
--]]

require "subclass/class.lua"
require "util/button.lua"
require "util/controlBag.lua"

background = class:new(...)

--[[
--Constructs a menu displaying all available backgrounds.
--Backgrounds must be in .png format to be listed in the menu.
--
--Requirement 1.2.3
--]]
function background:construct(aConfigBag)
	self.config = aConfigBag

	self.bgs = {}
	self.bgs = love.filesystem.enumerate("backgrounds/")

	self.bgButtons = {}
	local drawX = 200
	local drawY = 150
	for n,b in pairs(self.bgs) do
		--Require the file to have a .png in it
		if(string.find(b, ".png") ~= nil) then
			self.bgButtons[#self.bgButtons + 1] = button:new(b,drawX,drawY)
			self.bgButtons[#self.bgButtons]["bg"] = b
			drawX = drawX + 400
			if(drawX > 600) then
				drawX = 200
				drawY = drawY + 50
			end
		end
	end

	self.title = "CHANGE BACKGROUND"
	self.titleWidth = font["large"]:getWidth(self.title)
	self.default = button:new("Clear",400,500)
	self.exit = button:new("Back",400,550)
end

--[[
--Draws the list of backgrounds to the screen.
--
--Requirement 1.2.3
--]]
function background:draw()
	love.graphics.setFont(font["large"])
	love.graphics.setColor(unpack(color["text"]))
	love.graphics.print(self.title,400-self.titleWidth/2,50)
	for n,b in ipairs(self.bgButtons) do
		b:draw()
	end
	self.default:draw()
	self.exit:draw()
end

--[[
--Highlights a button with the cursor over it.
--]]
function background:update(dt)
	for n,b in ipairs(self.bgButtons) do
		b:update(dt)
	end
	self.default:update(dt)
	self.exit:update(dt)
end

--[[
--Captures the escape key to return to the graphics menu.
--]]
function background:keypressed(key)
	if(key == "escape") then
		self:back()
	end
end

--[[
--Captures mousepresses by the user.
--If the user clicks on a background button, it assigns it and returns.
--If the user clicks the Back button, it returns to graphics.lua.
--
--Requirement 1.2.3
--]]
function background:mousepressed(x,y,button)
	if(self.exit:mousepressed(x,y,button)) then
		self:back()
	elseif(self.default:mousepressed(x,y,button)) then
		self.config:setBackground("")
		self:back()
	else
		for n,b in ipairs(self.bgButtons) do
			if(b:mousepressed(x,y,button)) then
				self.config:setBackground(b["bg"])
				self:back()
			end
		end
	end
end

--[[
--Returns to graphics.lua
-]]
function background:back()
	state = graphics:new(self.config)
end
