import "CoreLibs/graphics"
import "CoreLibs/object"
import 'blocktext'

local gfx = playdate.graphics

class('MainMenu').extends()

function MainMenu:init() 
	MainMenu.super.init(self)
end

function MainMenu:update() 
	gfx.clear()
	drawBlockText("PICTO PUZZLES", 25, 70, 5)

	drawBlockText("PUZZLES", 25, 150, 4, 0, true)
	gfx.setFont(blockyFont)
	
	-- gfx.drawTextAligned("PRESS A TO START", playdate.display.getWidth()/2.0, 150, kTextAlignment.center)		
		
	if playdate.buttonJustReleased(playdate.kButtonA) then 
		goLevelSelect(true)
	end
end 

