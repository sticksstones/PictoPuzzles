import 'CoreLibs/ui/gridview.lua'
import 'CoreLibs/nineslice'
import "CoreLibs/graphics"
import "CoreLibs/object"
import 'puzzle'

local gfx = playdate.graphics

local selectedGrid = 0

local gridFont = gfx.font.new('assets/blocky')
gridFont:setTracking(1)

local gridview = playdate.ui.gridview.new(44, 44)
local active = false

local levelData = json.decodeFile(playdate.file.open('assets/puzzles/puzzles.json'))

class('LevelSelect').extends()

function LevelSelect:init() 
	LevelSelect.super.init(self)

	gridview.backgroundImage = playdate.graphics.nineSlice.new('assets/shadowbox', 4, 4, 45, 45)
	gridview:setNumberOfColumns(#levelData['puzzles'])
	gridview:setNumberOfRows(1) -- number of sections is set automatically
	gridview:setSectionHeaderHeight(28)
	gridview:setContentInset(1, 4, 1, 4)
	gridview:setCellPadding(4, 4, 4, 4)
	gridview.changeRowOnColumnWrap = false
	active = true

end

function LevelSelect:update() 
	gfx.clear()	
	gridview:drawInRect(20, 20, 360, 200)
end

function gridview:drawCell(section, row, column, selected, x, y, width, height)
	if selected then
		gfx.setLineWidth(3)
		gfx.drawCircleInRect(x, y, width+1, height+1)
	else
		gfx.setLineWidth(0)
		gfx.drawCircleInRect(x+4, y+4, width-8, height-8)
	end
	local cellText = ""..row.."-"..column
	
	gfx.setFont(gridFont)
	gfx.drawTextInRect(cellText, x, y+18, width, 20, nil, nil, kTextAlignment.center)
end


function gridview:drawSectionHeader(section, x, y, width, height)
	gfx.drawText("*Section ".. section .. "*", x + 10, y + 8)
end

function playdate.upButtonUp()
	if active then 
		gridview:selectPreviousRow(true)
	end
end

function playdate.downButtonUp()
	if active then 
		gridview:selectNextRow(true)
	end 		
end

function playdate.leftButtonUp()
	if active then 
		gridview:selectPreviousColumn(true)
	end 
end

function playdate.rightButtonUp()
	if active then 
		gridview:selectNextColumn(true)
	end 
end

function playdate.AButtonDown() 
	if active then 
		local section,row,column = gridview:getSelection()
		active = false
		puzzleData = levelData['puzzles'][column]
		loadLevel(puzzleData)
	end	
end




