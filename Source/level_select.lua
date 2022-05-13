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
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)             
	gridview:drawInRect(20, 20, 360, 200)
	
	if playdate.buttonJustPressed(playdate.kButtonUp) then 
		gridview:selectPreviousRow(true)
	end 

	if playdate.buttonJustPressed(playdate.kButtonDown) then 
		gridview:selectNextRow(true)
	end 

	if playdate.buttonJustPressed(playdate.kButtonLeft) then 
		gridview:selectPreviousColumn(true)
	end 

	if playdate.buttonJustPressed(playdate.kButtonRight) then 
		gridview:selectNextColumn(true)
	end 

	if playdate.buttonJustPressed(playdate.kButtonA) then 
		local section,row,column = gridview:getSelection()
		active = false
		puzzleData = levelData['puzzles'][column]
		goLoadLevel(puzzleData)
	end 

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



