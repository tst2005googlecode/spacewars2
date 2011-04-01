require "subclass/class.lua"
require "util/bodyObj.lua"

missile = bodyObj:new(...)
local mass = 10

function missile:init(aWorld, x, y, startAngle, aCoordBag, shipConfig, xVel, yVel)
	self:initBody(aWorld, x, y, mass, mass * ( 25 * 10 ) * ( 100000 ^ 2 ) / 6)

	self.missilePoly = love.physics.newPolygonShape(self.body, 9, 0, -7, 7, -7, -7)
	self.body:setAngle(startAngle)
	self.body:setLinearVelocity(xVel,yVel)

	self.minX,self.maxX,self.screenX,self.minY,self.maxY,self.screenY = aCoordBag:getCoords()

	self.fuel = 6000
	self.killswitch = 6000
	self.holdTime = 5

	self.baseThrust = mass * 100
	self.baseTorque = mass ^ 3 * 10000
	self.easyTurn = 0.005 / timeScale

	self.missilePoly:setSensor(true)
	self.data = {}
	self.data.status = "MISSILE"
	self.data.owner = ""
	self.missilePoly:setData(self.data)

	self.target = {}
end

function missile:target(aBody)

end

function missile:draw()
	love.graphics.polygon("line", self.missilePoly:getPoints())
end

function missile:update(dt)
	if(self.data.status == "DEAD") then
		--Hold down timer to make sure EVERYTHING stops referencing it
		if(self.holdTime > 0) then
			self.holdTime = self.holdTime - 1
		else
			self:destroy()
		end
	--Missiles can't reliably track over the border, so it self-destructs safely
	elseif(self:offedge() == true) then
		self.data.status = "DEAD"
	--Missile has fuel to thrust with
	elseif(self.fuel > 0) then
		self:thrust()
		self.fuel = self.fuel - (1000 * dt)
	--Missile drifts until killswitch time elapses
	elseif(self.killswitch > 0) then
		self.killswitch = self.killswitch - (1000 * dt)
	--Missile is marked DEAD
	else
		self.data.status = "DEAD"
	end
end

function missile:destroy()
	self.missilePoly:destroy()
	self.body:destroy()
	self.missilePoly = nil
	self.body = nil
	self.minX,self.maxX,self.minY,self.maxY,self.screenX,self.screenY = nil
	self.fuel,self.killswitch = nil
	self.baseThrust,self.baseTorque,self.easyTurn = nil
	self.data.owner = nil
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
	end
	if(self.body:getX() < self.minX) then
		return true
	end
	if(self.body:getY() > self.maxY) then
		return true
	end
	if(self.body:getY() < self.minY) then
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

function missile:getBody()
	return self.body
end

function missile:getType()
	return "missile"
end
