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

objectBag.lua ... part of object framework

This class is a data structure for holding an object type and all its instances.
All instances are held in the objects list
Inactive or destroyed objects are added to the recycled list by id.
When a new object is requested, the recycled list is checked.
	If an instance exists, the last instance in the recycled list is returned.
	Otherwise a new object is created and added to the objects table.
--]]

require "subclass/class.lua"

local objectClass -- reference to class that will construct and constructialize objects
local objects     -- list of objects in this container
local recycled    -- object references that are recycled

objectBag = class:new(...)

--[[
--Constructs and initializes a new objectBag to hold instances.
--]]
function objectBag:construct( anObjectClass )
	assert( anObjectClass ~= nil, "class object is nil" )
	--This bag holds this type of object.
	self.objectClass = anObjectClass
	self.objects = {}
	self.recycled = {}
end

--[[function objectBag:getType()
	return self.objectType
end

function objectBag:getObjects()
	return self.objects
end

function objectBag:getRecycled()
	return self.recycled
end--]]

--[[
--An object no longer in play is recycled.
--The calling class is responsibile for putting the object in the right bag.
--]]
function objectBag:recycle( anObject )
	self.recycled[ #self.recycled + 1 ] = anObject -- self.objects[ anObject.index ]
end

--[[
--Returns the total instances of the objectBag's holding type.
--]]
function objectBag:getCount()
	return #self.objects
end

--[[
--If a recycled instance exists, pop the bottom off the table and returns it.
--Otherwise, it creates a new instance of the type.
--]]
function objectBag:getNew( ... )
	local anObject
	if #self.recycled > 0 then
		--Reuse an object
		anObject = table.remove( self.recycled, #self.recycled )
		anObject:activate()
		if anObject.init then
			--Initialize the object.
			anObject:init( ... )
		end
		if not anObject.isActive then objectBag:error() end --Initialization failed.
	else
		--Create a new object
		anObject = self.objectClass:new( ... )
		self.objects[ #self.objects + 1 ] = anObject
		anObject.index = #self.objects
	end
	return anObject
end
