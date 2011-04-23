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

playerconfig = class:new(...)
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
      self.buttons = {GameSpeed =  button:new("Game Speed = " .. self.control["GameSpeed"], 400, 100),
			NumberofAI = button:new("Number of AI = " .. self.control["NumberofAI"] ,400, 150),
			RandomOpponents = button:new("Random Opponents = " .. self.control["RandomOpponents"], 400, 200),
			Moons = button:new("Moons = " .. self.control["Moons"], 400, 250),
            RandomMoons = button:new("Random Moons = " .. self.control["RandomMoons"], 400, 300),
			SolarDebris = button:new("Solar Debris = " .. self.control["SolarDebris"], 400, 350),
			PlayerRespawns = button:new("Player Respawns = " .. self.control["PlayerRespawns"] , 400,400),
                        Back = button:new("Back" , 400, 550)}
--We do not need input and have nothing to change in a new view.
	self.needInput = false
	self.change = ""
end

--Draws the various buttons to the screen.

function playerconfig:draw()
	love.graphics.setFont(font["small"])
--Draw the buttons
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function playerconfig:mousepressed(x,y,button)
	if(self.needInput == false) then
		for n,b in pairs(self.buttons) do
			if b:mousepressed(x,y,button) then
				if n == "Back" then
					self:back() --Return to a higher menu
				else
					self.needInput = true
					self.change = n --This is where input will go
				end
			end
		end
	end
end

