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

This class is a data structure for holding an object type and its tables that 
manage the object life.  All objects are held in the objects list ... inactive 
or destroyed objects are added to the recycled list by id.  When a new 
object is requested, the recycled list is first checked, and the last object in 
the recycled list is returned if exists, otherwise a new object is created and 
added to the objects table.
--]]

require "subclass/class.lua"

local objectClass -- reference to class that will construct and constructialize objects
local objects     -- list of objects in this container
local recycled    -- object references that are recycled

objectBag = class:new(...)

function objectBag:construct( anObjectClass )
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

-- recycle an object no longer in play
function objectBag:recycle( anObject )
	self.recycled[ #self.recycled + 1 ] = self.objects[ anObject.index ]
end

-- returns number of objects created
function objectBag:getCount()
	return #self.objects
end

-- this will return an object of the configured type
function objectBag:getNew( ... )
	local anObject
	if #self.recycled > 0 then -- reuse an object
		anObject = table.remove( self.recycled )
		print( "reuse ", anObject.index )
		anObject:activate()
		if anObject.init then
			anObject:init( ... )
		end
		if not anObject.isActive then objectBag:error() end
	else -- create a new object
		anObject = self.objectClass:new( ... )
		self.objects[ #self.objects + 1 ] = anObject
		anObject.index = #self.objects
	end
	return anObject
end
