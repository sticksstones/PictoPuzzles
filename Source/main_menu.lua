import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/ui"
import 'blocktext'

local gfx = playdate.graphics

class('MainMenu').extends()

function MainMenu:init() 
	MainMenu.super.init(self)
end

local menuOptions = {"SOLVE", "CREATE", "EXPLORE"}
local listview = playdate.ui.gridview.new(0, 10)
-- listview.backgroundImage = playdate.graphics.nineSlice.new('scrollbg', 20, 23, 92, 28)
listview:setNumberOfRows(#menuOptions)
listview:setCellPadding(0, 0, 8, 5)
listview:setContentInset(24, 24, 13, 11)

function listview:drawCell(section, row, column, selected, x, y, width, height)
		if selected then
			gfx.fillRoundRect(x, y, width, 20, 4)
				-- gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		else
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		end
		gfx.drawTextInRect(string.upper(menuOptions[row]), x + 4, y+6, width, height, nil, "...", kTextAlignment.left)
end

function MainMenu:update() 
	gfx.clear()
	drawBlockText("PICTO PUZZLES", 25, 70, 5)

	-- drawBlockText("PUZZLES", 25, 150, 4, 0, true)
	gfx.setFont(blockyFont)
	
	listview:drawInRect(0, 110, 160, 210)
	-- gfx.drawTextAligned("PRESS A TO START", playdate.display.getWidth()/2.0, 150, kTextAlignment.center)		
		
	if playdate.buttonJustPressed(playdate.kButtonUp) then 
		listview:selectPreviousRow()
	end 

	
	if playdate.buttonJustPressed(playdate.kButtonDown) then 
		listview:selectNextRow()
	end 
	
	if playdate.buttonJustReleased(playdate.kButtonA) then
		selectedRow = listview:getSelectedRow()

		if selectedRow == 1 then 
			goLevelSelect(true)
		elseif selectedRow == 2 then 
			goLevelEditor()
		end 
	end
end 

