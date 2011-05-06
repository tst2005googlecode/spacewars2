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

gameHelp.lua

This class displays a basic help screen for the user.
The help contains a list of all the objects in the game world, except radar.
There is a description of each object accompanying.
--]]

require "util/ship.lua"
require "util/player.lua"
require "util/ai.lua"
require "util/solarMass.lua"
require "util/missile.lua"
require "util/laser.lua"
require "util/debris.lua"
require "util/controlBag.lua"
require "util/button.lua"

gameHelp = class:new(...)

--[[
--Constructs a gameHelp screen for the user.
--All objects are constructed and given positions.
--In addition, all text strings are initialized.
--
--Requirement 1.1.4
--]]
function gameHelp:construct(aConfigBag)
	--World holder variables.
	self.objects = {}
	self.theConfigBag = aConfigBag
	self.theWorld = love.physics.newWorld(0,0,sWidth,sHeight,0,0,true)
	self.theCoordBag = coordBag:new(0,sWidth,sWidth,0,sHeight,sHeight)

	--Build a player's Ship
	self.theConfigBag["color"] = color["ship"]
	self.theConfigBag["shipType"] = "playerShip"
	self.thePlayer = player:new( self.theCoordBag, self.theConfigBag )
	self.theConfigBag:setStartPosition(100,75,0)
	self.playerShip = ship:new(self.theWorld,self.thePlayer,self.theCoordBag,self.theConfigBag)
	self.objects[#self.objects + 1] = self.playerShip

	--Build a missile, must be done now before changing the configBag
	self.theMissile = missile:new(self.theWorld,100,225,0,self.theCoordBag,self.theConfigBag,0,0)
	self.objects[#self.objects + 1] = self.theMissile

	--Build an ai's ship
	self.theConfigBag["color"] = color["ai"]
	self.theConfigBag["shipType"] = "aiShip"
	self.theAi = ai:new( self.theCoordBag, self.theConfigBag )
	self.theConfigBag:setStartPosition(100,125,0)
	self.aiShip = ship:new(self.theWorld,self.theAi,self.theCoordBag,self.theConfigBag)
	self.objects[#self.objects + 1] = self.aiShip

	--Build a laser
	self.theLaser = laser:new(self.theWorld,0,175,0,self.theCoordBag,self.playerShip,0,0)
	self.theLaser:setOwner(self.thePlayer)
	self.objects[#self.objects + 1] = self.theLaser

	--Build a debris
	self.theDebris = debris:new(self.theWorld,self.theCoordBag,"ship",100,275,0,0,100)
	self.objects[#self.objects + 1] = self.theDebris

	--Build a solarMass
	self.theSolarMass = solarMass:new(self.theWorld,100,325,1,25,0,{34,139,34,255})
	self.objects[#self.objects + 1] = self.theSolarMass

	--Construct all the strings to be written to the screen.
	self.title = "GAME HELP"
	self.playerString = "This is you.  You can thrust, turn, and fire weapons!"
	self.aiString = "This is the enemy.  He can do what you can do, but he's evil!"
	self.laserString = "This is a laser.  It travels quickly, but does little damage!"
	self.missileString = "This is a missile.  It travels slowly, but does great damage!"
	self.debrisString = "This is debris.  It can damage you, but you can blow it up!"
	self.solarString = "This is a planet or moon.  It destroys anything it touches!"
	--This starts the HUD information.
	self.HUD = "FKSLAME"
	self.digits = love.graphics.newImageFont( "images/digits.png", "1234567890.-AEFKLMS: " )
	self.HUDstring = "These are your HUD icons, from left to right..."
	self.updateString = "Game updates per second.  High numbers = smooth gameplay."
	self.killString = "Number of destroyed enemies.  Blow all those CPUs up!"
	self.scoreString = "Your score, which is kills/deaths.  Aim for the top!"
	self.lifeString = "Your number of remaining ships.  Careful not to run out!"
	self.armorString = "How much armor you have.  If this reaches 0, you die!"
	self.missileString = "Your number of remaining missiles.  Fire with right mouse button!"
	self.laserString = "Your remaining laser charges.  Fire with the left mouse button!"

	--Construct a back button
	self.backButton = button:new("Back",400,580)
end

--[[
--Draws all the objects and information to the screen.
--
--Requirement 1.1.4
--]]
function gameHelp:draw()
	--Draw all the objects
	for i,v in ipairs(self.objects) do
		v:draw()
	end
	--Draw the title.
	love.graphics.setFont(font["large"])
	love.graphics.setColor(unpack(color["text"]))
	local width = font["large"]:getWidth(self.title)
	--Draw all the help text.
	local drawX = 250
	local drawY = 65
	love.graphics.print(self.title,400 - width/2,10)
	love.graphics.setFont(font["small"])
	love.graphics.print(self.playerString,drawX,drawY)
	drawY = drawY + 50
	love.graphics.print(self.aiString,drawX,drawY)
	drawY = drawY + 50
	love.graphics.print(self.laserString,drawX,drawY)
	drawY = drawY + 50
	love.graphics.print(self.missileString,drawX,drawY)
	drawY = drawY + 50
	love.graphics.print(self.debrisString,drawX,drawY)
	drawY = drawY + 50
	love.graphics.print(self.solarString,drawX,drawY)
	drawY = drawY + 50

	--This starts the HUD help.
	love.graphics.print(self.HUDstring,drawX,drawY)
	drawY = drawY + 20
	love.graphics.print(self.updateString,drawX,drawY)
	drawY = drawY + 20
	love.graphics.print(self.killString,drawX,drawY)
	drawY = drawY + 20
	love.graphics.print(self.scoreString,drawX,drawY)
	drawY = drawY + 20
	love.graphics.print(self.lifeString,drawX,drawY)
	drawY = drawY + 20
	love.graphics.print(self.armorString,drawX,drawY)
	drawY = drawY + 20
	love.graphics.print(self.missileString,drawX,drawY)
	drawY = drawY + 20
	love.graphics.print(self.laserString,drawX,drawY)

	--Draw the HUD icons
	love.graphics.setColor(255,255,255,255)
	love.graphics.setFont(self.digits)
	love.graphics.print(self.HUD,40,435,0,3,3)

	--Draw the back button.
	self.backButton:draw()
end

--[[
--Catches the mouse click on the exit button.
--]]
function gameHelp:mousepressed(x,y,button)
	if(self.backButton:mousepressed(x,y,button)) then
		self:back()
	end
end

--[[
--Catches the escape key to leave the menu.
--]]
function gameHelp:keypressed(key)
	if(key == "escape") then
		self:back()
	end
end

--[[
--Causes the backbutton to highlight when hovered over.
--]]
function gameHelp:update(dt)
	self.backButton:update(dt)
end

--[[
--Return to the main menu.
--Destroys all the objects created by the instance.
--]]
function gameHelp:back()
	self.objects = {}
	self.theWorld = {}
	self.theCoordBag = {}
	self.thePlayer = {}
	self.playerShip = {}
	self.theAi = {}
	self.aiShip = {}
	self.theLaser = {}
	self.theMissile = {}
	self.theDebris = {}
	self.theSolarMass = {}

	state = menu:new(self.theConfigBag)
	self.configBag = {}
	self = {}
end
