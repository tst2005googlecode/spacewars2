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

button.lua

This class implements a simple textual button.
The button consists of text and position.
Buttons highlight when the cursor is over them.

This class does not directly fulfill any requirements.
Instead, it assists with fulfilling all menu requirements.
--]]

require "subclass/class"
button = class:new(...)

--[[
--Construct and initialize a button for the screen.
--]]
function button:construct(text,x,y)
	--New buttons are not hovered or clicked.
	self.hover = false
	self.click = false
	--Set the initial properties.
	self.text = text
	self.width = font["large"]:getWidth(text)
	self.height = font["large"]:getHeight()
	self.x = x - (self.width / 2)
	self.y = y

end

--[[
--Draw a button to the screen.
--If the button is hovered over, then highlight it.
--]]
function button:draw()
	love.graphics.setFont(font["large"])
	if self.hover then love.graphics.setColor(unpack(color["main"]))
	else love.graphics.setColor(unpack(color["text"])) end
	love.graphics.print(self.text, self.x, self.y-36)

end

--[[
--Updates a button.
--If the mouse is over the button, then flag it for highlighting.
--Otherwise, ensure the button is NOT flagged.
--]]
function button:update(dt)
	local x = love.mouse.getX()
	local y = love.mouse.getY()

	if x > self.x
		and x < self.x + self.width
		and y > self.y - self.height
		and y < self.y then
		self.hover = true
	else
		self.hover = false
	end
end

--[[
--Checks if a button has been clicked.
--If a button is flagged as hovered, then it is logically the button clicked.
--]]
function button:mousepressed(x, y, button)
	if self.hover then
		if audio then
			love.audio.play(sound["click"])
		end
		return true
	end
	return false
end

--[[
--Provides support for changing a button's text.
--Most notably used to change a button to reflect new user configurations.
--]]
function button:changeText(theText)
	self.text = theText
end
