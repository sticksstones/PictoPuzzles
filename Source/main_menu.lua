import "CoreLibs/graphics"
import "CoreLibs/object"
import "game"
import "main"

local gfx = playdate.graphics

local kMenuStateMain, kMenuStateLevelSelect, kMenuStatePlaying = 0, 1, 2

class('MainMenu').extends()

function MainMenu:init() 
	MainMenu.super.init(self)
	self.currentState = kMenuStateMain
	self.game = nil
end

function MainMenu:startGame() 
	self.currentState = kMenuStatePlaying
	self.game = Game()
	self.game:loadRandomPuzzle()	
end 

function MainMenu:update() 
	if self.currentState == kMenuStateMain then 
		gfx.clear()
		gfx.drawTextAligned("PICTO PUZZLES", playdate.display.getWidth()/2.0, 15, kTextAlignment.center)		
		
		if playdate.buttonJustReleased(playdate.kButtonA) then 
			self:startGame()
		end
	elseif self.currentState == kMenuStatePlaying then 
		self.game:update()
	end	
end 