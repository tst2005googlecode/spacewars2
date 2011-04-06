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

This class implements the controls menu for Spacewars!II.
--]]

require "subclass/class.lua"
require "util/button.lua"
require "util/controlBag.lua"

controls = class:new()

function controls:construct(aControlBag)
	self.control = {}
	self.control["Thrust"] = aControlBag:getThrust()
        self.control["Left"] =  aControlBag:getLeft()
        self.control["Reverse"] = aControlBag:getReverse()
        self.control["Right"] = aControlBag:getRight()
        self.control["StopTurn"] = aControlBag:getStopTurn()
        self.control["StopThurst"] = aControlBag:getStopThrust()
        
        
         
        

	self.buttons = {Thrust =  button:new("Thrust = " .. self.control["Thrust"], 400, 100),
			Reverse = button:new("Reverse = " .. self.control["Reverse"] ,400, 150),
			Left = button:new("Left = " .. self.control["Left"], 400, 200),
			Right = button:new("Right = " .. self.control["Right"], 400, 250),
			StopTurn = button:new("StopTurn = " .. self.control["StopTurn"], 400, 300),
			StopThrust = button:new("StopThrust = " .. self.control["StopThurst"] , 400,350),
					Back = button:new("Back" , 400, 550)}
	self.needInput = false
	self.change = ""
end

function controls:draw()
	love.graphics.setFont(font["small"])
	if(self.needInput == true) then
		love.graphics.print("Please enter the key for " .. self.change,100,450)
	end
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function controls:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

function controls:mousepressed(x,y,button)
	if(self.needInput == false) then
		for n,b in pairs(self.buttons) do
			if b:mousepressed(x,y,button) then
				if n == "Back" then
					self:back()
				else
					self.needInput = true
					self.change = n
				end
			end
		end
	end
end

function controls:keypressed(key)
	if key == "escape" then
		self:back()
		state = menu:new()
	elseif self.needInput == true then
		self.control[self.change] = key
		self.needInput = false
		self.buttons[self.change]:changeText(self.change .. " = " .. self.control[self.change])
	end
end

function controls:back()
	local theControlBag = controlBag:new(self.control["Thrust"],self.control["Left"],self.control["Reverse"],
                   self.control["Right"],self.control["StopTurn"],self.control["StopThurst"],"r","NORMAL",100000)
	state = menu:new(theControlBag)
end
