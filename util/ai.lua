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

ai.lua

This class implements an ai controller.
ai flies for 1000 update cycles before killing ignition.
--]]

require "subclass/class.lua"

ai = class:new(...)

--[[
--Constructs and initializes the ai controller.
--]]
function ai:construct()
	self.cycles = 1000 --Fly for 1000 update cycles
	self.state = { respawn = false } --New ships don't need to respawn
	self.control = "A"
end
--[[
--Poll the ai for control input.
--Return the input to the ship that asked for it.
--]]
function ai:updateControls( shipState, dt )
	--Create a table to hold the commands
	local commands = {}
	--If dead, the AI should respawn instantly with a new ignition timer.
	if self.state.respawn then
		commands[ #commands + 1 ] = "respawn"
		self.state.respawn = false
		self.cycles = 1000
	--If the AI has time left, then it can still thrust
	elseif self.cycles > 0 then
		commands[ #commands + 1 ] = "thrust"
		self.cycles = self.cycles - dt * timeScale
	end

	return commands
end


function ai:getControl()
	return self.control
end
