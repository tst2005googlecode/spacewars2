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

pause.lua

This class implements a pause screen.
It takes the current state of the game and stores it temporarily.
If resume is selected, or ESC is pressed again, it restores the game state.
--]]

require "subclass/class.lua"
require "util/button.lua"

pause = class:new(...)

function pause:construct(aGame, aControlBag)
	love.mouse.setVisible( true ) -- hide the mouse cursor
	self.temp = aGame
	self.tempControl = aControlBag
	self.buttons = {resume = button:new("Resume", 400, 250),
					quit = button:new("Quit", 400, 350)}
end

function pause:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

function pause:mousepressed(x, y, button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,buttons) then
			if n == "resume" then
				state = self.temp
				love.mouse.setVisible( false ) -- hide the mouse cursor
			elseif n == "quit" then
				self.temp:destroy()
				state = menu:new(self.tempControl)
			end
		end
	end
end

function pause:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function pause:keypressed(key)
	if key == "escape" then
		state = self.temp
		love.mouse.setVisible( false ) -- hide the mouse cursor
	end
end
