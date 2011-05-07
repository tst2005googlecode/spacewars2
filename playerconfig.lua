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

playerconfig.lua

This class implements the player configuration menu for Spacewars!II.
The player can change the Game speed, Number of AI, Shield Strength, Number of Debris, Number of Moons

--]]

require "subclass/class.lua"
require "util/button.lua"
require "util/controlBag.lua"
require "help/configHelp.lua"

playerconfig = class:new(...)

--Constants for minimum and maximum values
local minSpawn = 1
local maxSpawn = 30
local minSpeed = 1
local maxSpeed = 500
local minMoons = 0
local maxMoons = 9
local minAI = 1
local maxAI = 9
local minDebris = 0
local maxDebris = 200
--[[
--Both creates and initializes the playerconfig menu based on current settings.
--
--Requirement 1.2.2
--]]
function playerconfig:construct(aControlBag)
	--Store the configuration
	self.bag = aControlBag

	--Load the appropriate controls for user configuration
	self.control = {}
        self.control["GameSpeed"] = aControlBag:getSpeed()
        self.control["NumberofAI"] = aControlBag:getAiNum()
        self.control["RandomOpponents"] = aControlBag:getRandomAi()
        self.control["Moons"] = aControlBag:getMoonNum()
        self.control["RandomMoons"] = aControlBag:getRandomMoon()
        self.control["SolarDebris"] = aControlBag:getDebrisNum()
        self.control["PlayerRespawns"] = aControlBag:getLives()

  --Initialize the buttons the user can press
	self.buttons = {GameSpeed =  button:new("GameSpeed = " .. self.control["GameSpeed"], 400, 100),
		NumberofAI = button:new("NumberofAI = " .. self.control["NumberofAI"] ,400, 150),
		RandomOpponents = button:new("RandomOpponents = " .. self.control["RandomOpponents"], 400, 200),
		Moons = button:new("Moons = " .. self.control["Moons"], 400, 250),
		RandomMoons = button:new("RandomMoons = " .. self.control["RandomMoons"], 400, 300),
		SolarDebris = button:new("SolarDebris = " .. self.control["SolarDebris"], 400, 350),
		PlayerRespawns = button:new("PlayerRespawns = " .. self.control["PlayerRespawns"] , 400,400),
		Help = button:new("Help", 400, 450),
		exit = button:new("Back" , 400, 500)}

	self.needInput = false
	self.change = nil
	self.inputString = ""
end

--[[
--Draws the various buttons to the screen.
--Also shows a helpMessage with current input if the user changes a property.
--
--Requirement 1.2.2
--]]
function playerconfig:draw()
	love.graphics.setFont(font["small"])
	--Draw the buttons
	for n,b in pairs(self.buttons) do
		b:draw()
	end
	--Draw a helpMessage for the user.
	if(self.needInput) then
		local helpMessage = ""
		love.graphics.setFont(font["default"])
		--Update the helpMessage to show the latest stringInput



		if(self.change == "PlayerRespawns") then

			helpMessage = "Please enter a number between " .. minSpawn .. " and " .. maxSpawn .. ": " .. self.inputString

			--Use elseifs for the rest of the properties
                elseif(self.change == "GameSpeed") then

                 helpMessage = "Please enter a number between " .. minSpeed .. " and " .. maxSpeed .. ": " .. self.inputString

                elseif(self.change == "Moons") then

                 helpMessage = "Please enter a number between " .. minMoons .. " and " .. maxMoons .. ": " .. self.inputString

                elseif(self.change == "NumberofAI") then

                 helpMessage = "Please enter a number between " .. minAI .. " and " .. maxAI .. ": " .. self.inputString

                elseif(self.change == "SolarDebris") then

              helpMessage = "Please enter a number between " .. minDebris .. " and " .. maxDebris .. ": " .. self.inputString



		end
		love.graphics.print(helpMessage,100,550)
	end
end

--[[
--Polls the keyboard for user input.
--If escape is pressed, immediately exit the menu.
--If input is needed, and a digit is pressed, it is appended to the inputString
--	If backspace is pressed, the last character in the string is removed.
--	If return is pressed, error checking is done, and the value is stored.
--
--Requirement 1.2.2
--]]
function playerconfig:keypressed(key)
	if(key == "escape") then
		self:back()
	elseif(self.needInput == true) then
		if(key == "return") then
			--Catch the empty string to avoid an error!
			if(self.inputString == "") then
				self.needInput = false
				self.change = nil
				self.inputString = ""
			else
				--Use a generic number so we can also store the value genericly
				local number = self.inputString + 0 --Coerces to int
				--Check for errors based on the property!
				if(self.change == "PlayerRespawns") then
					if(number < 1) then
						number = 1
					elseif(number > 30) then
						number = 30
					end

					--More number checks

                                 elseif(self.change == "GameSpeed") then
                                          if(number < 1) then
                                          number = 1
                                 elseif(number > 500) then
                                          number = 500
                                        end

                                 elseif(self.change == "Moons") then
                                          if(number < 0) then
                                          number = 0

                                  elseif(number > 9) then
                                          number = 9
                                         end


                                 elseif(self.change == "NumberofAI") then
                                          if(number < 1) then
                                          number = 1

                                  elseif(number > 9) then
                                          number = 9
                                         end

                                  elseif(self.change == "SolarDebris") then
                                          if(number < 0) then
                                          number = 0

                                  elseif(number > 200) then
                                          number = 200
                                         end


				end
				--Generic storage operations
				self.control[self.change] = number
				self.buttons[self.change]:changeText(self.change .. " = " .. number)
				--Reset control variables
				self.needInput = false
				self.change = nil
				self.inputString = ""
			end
		elseif(key == "backspace") then
			--Erase the last character in the string if it's available
			len = string.len(self.inputString)
			if(len > 0) then
				self.inputString = string.sub(self.inputString,1,len-1)
			end
		elseif(string.len(key) == 1) then
			--Append the character if it's a digit
			if(string.find(key,"%d") ~= nil) then
				self.inputString = self.inputString .. key
			end
		end
	end
end

--[[
--Polls the mouse for input.
--If the exit button is pressed, then exit the menu.
--If toggled buttons are pressed, then the value is toggled
--Other buttons set the input flag and stores the property to be changed.
--
--Requirement 1.2.2
--]]
function playerconfig:mousepressed(x,y,button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,button) then
			if (n == "exit") then
				self:back() --Return to a higher menu
			elseif(n == "Help") then
				state = configHelp:new(self.bag)

			elseif (n == "RandomOpponents") then
				--Toggle the property
				if(self.control["RandomOpponents"] == "yes") then
					self.control["RandomOpponents"] = "no"
				else
					self.control["RandomOpponents"] = "yes"
				end
				self.buttons["RandomOpponents"]:changeText("RandomOpponents = " .. self.control["RandomOpponents"])
			elseif (n == "RandomMoons") then
				--Toggle the property

                             if(self.control["RandomMoons"] == "yes") then
					self.control["RandomMoons"] = "no"
				else
					self.control["RandomMoons"] = "yes"
				end
				self.buttons["RandomMoons"]:changeText("RandomMoons = " .. self.control["RandomMoons"])




			else
				self.needInput = true
				self.change = n
			end
		end
	end
end

--[[
--Highlights a button if it has been hovered over.
--]]
function playerconfig:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

--[[
--Returns to the options menu after assigning all properties.
--]]
function playerconfig:back()
	self.bag:setLives(self.control["PlayerRespawns"])
        self.bag:setSpeed(self.control["GameSpeed"])
        self.bag:setMoonNum(self.control["Moons"])
		self.bag:setRandomMoon(self.control["RandomMoons"])
        self.bag:setAiNum(self.control["NumberofAI"])
        self.bag:setDebrisNum(self.control["SolarDebris"])
		self.bag:setRandomAi(self.control["RandomOpponents"])
	state = options:new(self.bag)
end
