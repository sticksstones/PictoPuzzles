import "CoreLibs/graphics"
import "CoreLibs/object"
import 'blocktext'

local gfx = playdate.graphics
local gridFont = gfx.font.new('assets/blocky')

class('MainMenu').extends()

function MainMenu:init() 
	MainMenu.super.init(self)
end

function MainMenu:update() 
	gfx.clear()
	gfx.setFont()
	-- gfx.drawTextAligned("PICTO PUZZLES", playdate.display.getWidth()/2.0, 15, kTextAlignment.center)		
	drawBlockText("PICTO PUZZLES", 25, 70, 5)

	drawBlockText("PUZZLES", 25, 150, 4, 0, true)
	gfx.setFont(gridFont)
	-- playdate.display.setScale(4.0)
	
	-- gfx.drawTextAligned("PRESS A TO START", playdate.display.getWidth()/2.0, 150, kTextAlignment.center)		
		
	if playdate.buttonJustReleased(playdate.kButtonA) then 
		goLevelSelect(true)
	end
end 

