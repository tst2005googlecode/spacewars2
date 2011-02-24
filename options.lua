require "subclass/class.lua"
require "util/button.lua"

options = class:new()

function options:init()
	self.buttons = {back = button:new("Back", 400, 550)}
end

function options:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function options:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

function options:mousepressed(x,y,button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,button) then
			if n == "back" then
				state = menu:new()
			end
		end
	end
end

function options:keypressed(key)
	if key == "escape" then
		state = menu:new()
	end
end
