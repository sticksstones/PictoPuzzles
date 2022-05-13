import "CoreLibs/graphics"
import "CoreLibs/object"
import "level_select"
import 'Game'

local gfx = playdate.graphics

local kMenuStateMain, kMenuStateLevelSelect, kMenuStatePlaying = 0, 1, 2

class('MainMenu').extends()

function MainMenu:init() 
	MainMenu.super.init(self)
	self.currentState = kMenuStateMain
	self.game = nil
	self.levelSelect = nil
end

function MainMenu:startLevelSelect() 
	self.currentState = kMenuStateLevelSelect
	self.levelSelect = LevelSelect()
end 

function MainMenu:loadLevel(puzzleData)
	self.currentState = kMenuStatePlaying
	self.game = Game(puzzleData)
end 

function MainMenu:update() 
	if self.currentState == kMenuStateMain then 
		gfx.clear()
		gfx.drawTextAligned("PICTO PUZZLES", playdate.display.getWidth()/2.0, 15, kTextAlignment.center)		
		
		if playdate.buttonJustReleased(playdate.kButtonA) then 
			self:startLevelSelect()
		end
	elseif self.currentState == kMenuStateLevelSelect then 
		self.levelSelect:update()
	elseif self.currentState == kMenuStatePlaying then 
		self.game:update()
	end	
end 

