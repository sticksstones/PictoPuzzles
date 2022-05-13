import 'game'
import 'main_menu'

local initialized = false
local menu = nil 

local function initialize() 
   menu = MainMenu()   
   initialized = true
end

function playdate.update()
   if not initialized then 
      initialize()
   end 
   
   menu:update()
end
