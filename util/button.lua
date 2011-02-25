require "subclass/class"
button = class:new(...)

-----------------------
-- Handles buttons and such.
-----------------------

function button:init(text,x,y)
	self.hover = false
	self.click = false
	self.text = text
	self.width = font["large"]:getWidth(text)
	self.height = font["large"]:getHeight()
	self.x = x - (self.width / 2)
	self.y = y

end

function button:draw()

	love.graphics.setFont(font["large"])
	if self.hover then love.graphics.setColor(unpack(color["main"]))
	else love.graphics.setColor(unpack(color["text"])) end
	love.graphics.print(self.text, self.x, self.y-36)

end

function button:update(dt)
	self.hover = false

	local x = love.mouse.getX()
	local y = love.mouse.getY()

	if x > self.x
		and x < self.x + self.width
		and y > self.y - self.height
		and y < self.y then
		self.hover = true
	end
end

function button:mousepressed(x, y, button)

if self.hover then
		if audio then
			love.audio.play(sound["click"])
		end
		return true
	end
	return false
end
