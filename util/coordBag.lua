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

coordBag.lua

This class is a data structure for holding a game's border coordinates.
It keeps track of the minimum and maximum X and Y positions.
It also keeps track of the X and Y dimensions of the window.
Values can be returned individually, or in bulk.
This is a useful standard for passing border coords to a function.
--]]

require "subclass/class.lua"

coordBag = class:new(...)

--[[
--Constructs and initializes the bag with all coordinate data.
--
--Requirement 2.1
--]]
function coordBag:construct(aMinX,aMaxX,aScreenX,aMinY,aMaxY,aScreenY)
	self.minX = aMinX
	self.maxX = aMaxX
	self.screenX = aScreenX
	self.minY = aMinY
	self.maxY = aMaxY
	self.screenY = aScreenY
end

--[[
--Get the world's minimum X position.
--]]
function coordBag:getMinX()
	return self.minX
end

--[[
--Get the world's maximum X position.
--]]
function coordBag:getMaxX()
	return self.maxX
end

--[[
--Get the screen's width.
--]]
function coordBag:getScreenX()
	return self.screenX
end

--[[
--Get the world's minimum Y position.
--]]
function coordBag:getMinY()
	return self.minY
end

--[[
--Get the world's maximum Y position.
--]]
function coordBag:getMaxY()
	return self.maxY
end

--[[
--Get the screen's height.
--]]
function coordBag:getScreenY()
	return self.screenY
end

--[[
--Get all six coordinates from one call.
--]]
function coordBag:getCoords()
	return self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY
end
