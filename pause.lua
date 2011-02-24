require "subclass/class.lua"
require "util/button.lua"

pause = class:new(...)

function pause:init(aGame)
	temp = aGame
	self.buttons = {resume = button:new("Resume", 400, 250),
					quit = button:new("Quit", 400, 350)}
end

function pause:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

function pause:mousepressed(x, y, button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,buttons) then
			if n == "resume" then
				state = temp
			elseif n == "quit" then
				state = menu:new()
			end
		end
	end
end

function pause:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function pause:keypressed(key)
	if key == "escape" then
		state = temp
	end
end
