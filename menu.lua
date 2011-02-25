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

menu.lua

This class implements the main menu for Spacewars!II.
--]]

require "game.lua"
require "options.lua"
require "subclass/class.lua"
require "util/button.lua"

menu = class:new(...)

function menu:init()
	self.buttons = {new = 	button:new("New Game", 400, 250),
					options = 	button:new("Options", 400, 350),
					exit = 		button:new("Exit", 400, 550)}

end

function menu:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

function menu:mousepressed(x, y, button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,buttons) then
			if n == "new" then
				state = game:new()
			elseif n == "options" then
				state = options:new()
			elseif n == "exit" then
				love.event.push("q")
			end
		end
	end
end

function menu:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function menu:keypressed(key)
	if key == "escape" then
		love.event.push("q")
	end
end
