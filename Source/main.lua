import 'main_menu'

local initialized = false
menu = nil 

local function initialize() 
   menu = MainMenu()   
   initialized = true
end

function playdate.update()
   playdate.timer.updateTimers()
   
   if not initialized then 
      initialize()
   end 
   
   menu:update()
end


function loadLevel(puzzleData)
   menu:loadLevel(puzzleData)
end 