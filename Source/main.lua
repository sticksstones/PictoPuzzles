import 'main_menu'
import 'level_select'
import 'game'

local osMenu = playdate.getSystemMenu()
local initialized = false
menu = nil 

local kGameStateMainMenu, kGameStateLevelSelect, kGameStatePlaying, kGameStatePaused = 0, 1, 2,3
local gameState = kGameStateMainMenu

menu = MainMenu()   
game = Game()
levelSelect = LevelSelect()

function playdate.update()
   playdate.timer.updateTimers()
         
   if gameState == kGameStateMainMenu then 
      menu:update()   
   elseif gameState == kGameStateLevelSelect then 
      levelSelect:update()
   elseif gameState == kGameStatePlaying then 
      game:update()
   end	

end

function setState(newState)
   gameState = newState
end 

function goLevelSelect() 
   setState(kGameStateLevelSelect)
end 

function goLoadLevel(puzzleData)
   setState(kGameStatePlaying)
   game:loadPuzzle(puzzleData)
end 

function exitPuzzle() 
   goLevelSelect()   
end 



function playdate.gameWillPause()

   local menuItem, error = osMenu:addMenuItem("Exit Puzzle", exitPuzzle())
   
   local checkmarkMenuItem, error = osMenu:addCheckmarkMenuItem("Item 2", true, function(value)
       print("Checkmark menu item value changed to: ", value)
   end)
end 

function playdate.gameWillResume() 
   osMenu:removeAllMenuItems()
end

