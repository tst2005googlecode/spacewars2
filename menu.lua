require "game.lua"
require "options.lua"
require "subclass/class.lua"
require "util/button.lua"

menu = class:new(...)

function menu:init()
	self.buttons = {new = 	button:new("New Game", 400, 250),
					options = 	button:new("Options", 400, 350),
					exit = 		button:new("Exit", 400, 550)}

end

function menu:update(dt)
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
end

function menu:mousepressed(x, y, button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,buttons) then
			if n == "new" then
				state = game:new()
			elseif n == "options" then
				state = options:new()
			elseif n == "exit" then
				love.event.push("q")
			end
		end
	end
end

function menu:draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function menu:keypressed(key)
	if key == "escape" then
		love.event.push("q")
	end
end
