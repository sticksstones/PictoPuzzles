import 'main_menu'
import 'level_select'
import 'level_editor'
import 'game'
import 'save_funcs'

local gfx = playdate.graphics
local osMenu = playdate.getSystemMenu()
local initialized = false
menu = nil 

-- beep boop
synth = playdate.sound.synth.new(playdate.sound.kWavePOVosim)

-- crackle
noiseSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)

-- synth = playdate.sound.synth.new(playdate.sound.kWavePOVosim)

local kGameStateMainMenu, kGameStateLevelSelect, kGameStateLevelEditor, kGameStatePlaying, kGameStatePaused = 0, 1, 2, 3, 4
local gameState = kGameStateMainMenu

gridFont = gfx.font.new('assets/fonts/Picross-ExtraSmall')
gridFont:setTracking(0)
gridFont:setLeading(4)

gridFontNoKearning = gfx.font.new('assets/fonts/Picross-Small-no-kearning')
gridFontNoKearning:setTracking(2)

blockyFont = gfx.font.new('assets/fonts/blocky')
blockyFont:setTracking(1)

loadSave()

menu = MainMenu()   
game = Game()
levelSelect = LevelSelect()
levelEditor = LevelEditor()

playdate.display.setRefreshRate(30)

function playdate.update()
   playdate.timer.updateTimers()
         
   if gameState == kGameStatePlaying then 
      game:update()
   elseif gameState == kGameStateMainMenu then 
      menu:update()   
   elseif gameState == kGameStateLevelSelect then 
      levelSelect:update()
    elseif gameState == kGameStateLevelEditor then 
      levelEditor:update()
   end	

   playdate.drawFPS(0,0)

end

function setState(newState)
   if (gameState ~= newState) then
      gameState = newState
      osMenu:removeAllMenuItems()   
   end
  playdate.graphics.setDrawOffset(0,0)
end 

function goMainMenu() 
   setState(kGameStateMainMenu)
end 

function goLevelSelect(resetState) 
   resetState = resetState or false
   setState(kGameStateLevelSelect)
   if resetState then 
      levelSelect:start()
   end 
end 

function goLevelEditor() 
   setState(kGameStateLevelEditor)
   levelEditor:start()
   local menuItem, error = osMenu:addMenuItem("Save Puzzle", function() savePuzzle() end)
end 

function goLoadLevel(puzzle)
   setState(kGameStatePlaying)
   game:loadPuzzle(puzzle)
   local menuItem, error = osMenu:addMenuItem("[DEBUG] Finish", function() debugCompletePuzzle() end)
   local menuItem2, error2 = osMenu:addMenuItem("Leave Puzzle", function() exitPuzzle() end)   
end 

function exitPuzzle() 
   goLevelSelect()   
end 

function savePuzzle() 
  levelEditor:savePuzzle()
end 

function debugCompletePuzzle()
   game:debugCompletePuzzle()
end 

function playdate.gameWillPause()
   -- local checkmarkMenuItem, error = osMenu:addCheckmarkMenuItem("Item 2", true, function(value)
   --     print("Checkmark menu item value changed to: ", value)
   -- end)
end 

function playdate.gameWillResume() 
   -- osMenu:removeAllMenuItems()
end

function notifyGridChanged() 
  if gameState == kGameStatePlaying then 
    game:checkWin()
  elseif gameState == kGameStateLevelEditor then 
    levelEditor:gridChanged()
  end 
end

