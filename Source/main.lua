import 'main_menu'
import 'level_select'
import 'game'
import 'save_funcs'

local osMenu = playdate.getSystemMenu()
local initialized = false
menu = nil 

local kGameStateMainMenu, kGameStateLevelSelect, kGameStatePlaying, kGameStatePaused = 0, 1, 2,3
local gameState = kGameStateMainMenu

loadSave()

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

function goMainMenu() 
   setState(kGameStateMainMenu)
end 

function goLevelSelect() 
   setState(kGameStateLevelSelect)
   levelSelect:start()
end 

function goLoadLevel(puzzleData)
   setState(kGameStatePlaying)
   game:loadPuzzle(puzzleData)
end 

function exitPuzzle() 
   goLevelSelect()   
end 



function playdate.gameWillPause()

   local menuItem, error = osMenu:addMenuItem("Leave Puzzle", exitPuzzle())
   
   -- local checkmarkMenuItem, error = osMenu:addCheckmarkMenuItem("Item 2", true, function(value)
   --     print("Checkmark menu item value changed to: ", value)
   -- end)
end 

function playdate.gameWillResume() 
   osMenu:removeAllMenuItems()
end

