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
The player can change the Thrust, Left, Reverse, Right, Stop Turn, Stop Thrust
	Orbit, Zoom In, and Zoom Out keys, as well as the type of turning used.
--]]

require "subclass/class.lua"
require "util/button.lua"
require "util/controlBag.lua"
require "help/controlsHelp.lua"

controls = class:new()

--[[
--Both creates and initializes the controls menu based on current settings.
--
--Requirement 1.2.1
--]]
function controls:construct(aControlBag)
	--Store the configuration
	self.bag = aControlBag
	--Load the appropriate controls for user configuration
	self.control = {}
	self.control["Thrust"] = aControlBag:getThrust()
		self.control["Left"] =  aControlBag:getLeft()
        self.control["Reverse"] = aControlBag:getReverse()
        self.control["Right"] = aControlBag:getRight()
        self.control["StopTurn"] = aControlBag:getStopTurn()
        self.control["StopThrust"] = aControlBag:getStopThrust()
		self.control["Orbit"] = aControlBag:getOrbit()
        self.control["ZoomIn"] = aControlBag:getZoomIn()
        self.control["ZoomOut"] = aControlBag:getZoomOut()
		self.control["TurnType"] = aControlBag:getTurn()

	--Initialize the buttons the user can press
	self.buttons = {Thrust =  button:new("Thrust = " .. self.control["Thrust"], 200, 100),
			Reverse = button:new("Reverse = " .. self.control["Reverse"] ,200, 150),
			Left = button:new("Left = " .. self.control["Left"], 200, 200),
			Right = button:new("Right = " .. self.control["Right"], 200, 250),
			StopTurn = button:new("StopTurn = " .. self.control["StopTurn"], 600, 100),
			StopThrust = button:new("StopThrust = " .. self.control["StopThrust"] , 600,150),
			Orbit = button:new("Orbit = " .. self.control["Orbit"], 600,200),
			ZoomIn = button:new("ZoomIn = " .. self.control["ZoomIn"] , 400,300),
			ZoomOut = button:new("ZoomOut = " .. self.control["ZoomOut"] , 400,350),
			TurnType = button:new("TurnType = " .. self.control["TurnType"], 400,400),
			Help = button:new("Help", 400, 500),
			Back = button:new("Back" , 400, 550)}

	--We do not need input and have nothing to change in a new view.
	self.needInput = false
	self.change = ""
end

--[[
--Draws the various buttons to the screen.
--Also draws the "press key" message when the user elects to change a control.
--]]
function controls:draw()
	love.graphics.setFont(font["small"])
	--Instruct the user we need a keypress
	if(self.needInput == true) then
		love.graphics.print("Please enter the key for " .. self.change,100,450)
	end
	--Draw the buttons
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

--[[
--Updates the menu by highlighting a button the user has hovered over.
--]]
function controls:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

--[[
--When the mouse is pressed, it checks if a button is under the cursor.
--If it's the back button, it returns to a higher menu.
--Other buttons change state to support user input for the specified key.
--If a key has already been selected, nothing happens.
--]]
function controls:mousepressed(x,y,button)
	if(self.needInput == false) then
		for n,b in pairs(self.buttons) do
			if b:mousepressed(x,y,button) then
				if n == "Back" then
					self:back() --Return to a higher menu
				elseif n == "Help" then
					state = controlsHelp:new(self.bag)
				elseif n == "TurnType" then
					--Toggle the type of turn!
					if self.control["TurnType"] == "EASY" then
						self.control["TurnType"] = "NORMAL"
					else
						self.control["TurnType"] = "EASY"
					end
					self.buttons["TurnType"]:changeText("TurnType = " .. self.control["TurnType"])
				else
					self.needInput = true
					self.change = n --This is where input will go
				end
			end
		end
	end
end

--[[
--If the escape key is pressed, then return to a higher menu.
--Otherwise, if the state supports input, then assign key to the control.
--In addition, update the related button.
--
--Requirement 1.2.1
--]]
function controls:keypressed(key)
	if key == "escape" then
		self:back() --Return to a higher menu
	elseif self.needInput == true then
		self.control[self.change] = key
		self.needInput = false
		self.buttons[self.change]:changeText(self.change .. " = " .. self.control[self.change])
	end
end

--[[
--Assigns new properties to the configuration.
--Then, return to a higher menu with the configuration in tow.
--
--Requirement 1.2.1
--]]
function controls:back()
	--Assign each key individually
	self.bag:setThrust(self.control["Thrust"])
	self.bag:setLeft(self.control["Left"])
	self.bag:setReverse(self.control["Reverse"])
	self.bag:setRight(self.control["Right"])
	self.bag:setStopTurn(self.control["StopTurn"])
	self.bag:setStopThrust(self.control["StopThrust"])
	self.bag:setOrbit(self.control["Orbit"])
	self.bag:setZoomIn(self.control["ZoomIn"])
	self.bag:setZoomOut(self.control["ZoomOut"])
	self.bag:setTurn(self.control["TurnType"])
	state = options:new(self.bag)
end
