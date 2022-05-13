import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx = playdate.graphics
local gridFont = gfx.font.new('assets/blocky')

class('MainMenu').extends()

function MainMenu:init() 
	MainMenu.super.init(self)
end

function MainMenu:update() 
	gfx.clear()
	gfx.setFont()
	gfx.drawTextAligned("PICTO PUZZLES", playdate.display.getWidth()/2.0, 15, kTextAlignment.center)		

	gfx.setFont(gridFont)
	gfx.drawTextAligned("PRESS A TO START", playdate.display.getWidth()/2.0, 150, kTextAlignment.center)		
		
	if playdate.buttonJustReleased(playdate.kButtonA) then 
		goLevelSelect()
	end
end 

