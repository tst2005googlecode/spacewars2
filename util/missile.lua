require "subclass/class.lua"
require "util/bodyObject.lua"

local color
local mass = 10

missile = bodyObject:new(...)

-- object construction
function missile:construct(aWorld, x, y, startAngle, aCoordBag, shipConfig, xVel, yVel)
	self:constructBody(aWorld, x, y, 10, 10 * ( 25 * 10 ) * ( 100000 ^ 2 ) / 6)
	self.missilePoly = love.physics.newPolygonShape(self.body, 12, 0, 2, 4, -4, 4, -8, 0, -4, -4, 2, -4)
	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()
	self.missilePoly:setSensor(true)
	self.missilePoly:setData( self )
	self.holdTime = 5
	self.data = {}
	self.objectType = types.missile

	self:init( aWorld, x, y, startAngle, aCoordBag, shipConfig, xVel, yVel )
end

-- method to initialize or reinitialize object
function missile:init(aWorld, x, y, startAngle, aCoordBag, shipConfig, xVel, yVel)
	self.body:setAngle(startAngle)
	self.body:setLinearVelocity(xVel,yVel)
	self.body:setPosition( x, y )

	self.baseThrust = mass * 100
	self.baseTorque = mass ^ 3 * 10000
	self.easyTurn = 0.005 / timeScale

	self.color = shipConfig.color
	self.fuel = 6000
	self.killswitch = 6000
	self.target = {}

	self.data.owner = ""
	self.data.status = ""
end

function missile:target(aBody)

end

function missile:draw()
	if self.isActive then
		love.graphics.setColor( unpack( self.color ) )
		love.graphics.polygon("line", self.missilePoly:getPoints())
	end
end

function missile:update(dt)
	--[[if(self.data.status == "DEAD") then
		--Hold down timer to make sure EVERYTHING stops referencing it
		if(self.holdTime > 0) then
			self.holdTime = self.holdTime - 1
		else
			self:destroy()
		end
		return
	end--]]
	--Missiles can't reliably track over the border, so it self-destructs safely
	if(self:offedge() == true) then
		self:destroy()
	--Missile has fuel to thrust with
	elseif(self.fuel > 0) then
		self:thrust()
		self.fuel = self.fuel - (1000 * dt)
	--Missile drifts until killswitch time elapses
	elseif(self.killswitch > 0) then
		self.killswitch = self.killswitch - (1000 * dt)
	else -- out of time:  self destruct
		self:destroy()
	end
end

function missile:destroy()
	self:deactivate()
	self.data.status = "DEAD"
	-- set motion and postiont to zero, or will still move in the world
	self.body:setLinearVelocity( 0, 0 )
	self.body:setPosition( 0,0 )
	missiles:recycle( self )
end

function missile:thrust()
	local scaledThrust = self.baseThrust * forceScale
	local angle = self.body:getAngle()
	local xThrust = math.cos( angle ) * scaledThrust
	local yThrust = math.sin( angle ) * scaledThrust
	self.body:applyForce( xThrust, yThrust )
end

function missile:offedge()
	if(self.body:getX() > self.maxX) then
		return true
	elseif(self.body:getX() < self.minX) then
		return true
	end
	if(self.body:getY() > self.maxY) then
		return true
	elseif(self.body:getY() < self.minY) then
		return true
	end
	return false
end

function missile:getStatus()
	return self.data.status
end

function missile:setStatus(stat)
	self.data.status = stat
end

function missile:getOwner()
	return self.data.owner
end

function missile:setOwner(own)
	self.data.owner = own
end

function missile:getX()
	return self.body:getX()
end

function missile:getY()
	return self.body:getY()
end

function missile:getType()
	return "missile"
end
