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

options.lua

This class implements the options menu for Spacewars!II.
--]]

require "subclass/class.lua"
require "util/button.lua"

options = class:new()

function options:construct()
	self.buttons = {controls = button:new("Controls", 400, 350),
                          game = button:new("Game" , 400, 500)}   
 
end

function options:draw()
 
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function options:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

function options:mousepressed(x,y,button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,button) then
			if n == "controls" then
				state = controls:new()
                        elseif n == "game" then
                               state = menu:new()
			end
		end
	end
end

function options:keypressed(key)
	if key == "escape" then
		state = menu:new()
	end
end
