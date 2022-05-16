import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/ui"
import 'blocktext'

local gfx = playdate.graphics

local active = false

class('LevelEditor').extends()

function LevelEditor:init() 
	LevelEditor.super.init(self)
end

function LevelEditor:start() 
	active = true
end 

function LevelEditor:update() 
	gfx.clear()

	if playdate.buttonJustPressed(playdate.kButtonB) then 
		active = false
		goMainMenu()
	end 
end 

