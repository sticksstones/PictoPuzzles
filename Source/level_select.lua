import 'CoreLibs/ui/gridview.lua'
import 'CoreLibs/nineslice'
import "CoreLibs/graphics"
import "CoreLibs/object"
import 'puzzle'
import 'blocktext'

local gfx = playdate.graphics

local selectedGrid = 0

local gridview = playdate.ui.gridview.new(90, 60)
local active = false

local levelData = json.decodeFile(playdate.file.open('assets/puzzles/puzzles.json'))

cachedPuzzles = {}

class('LevelSelect').extends()

function LevelSelect:init() 
	LevelSelect.super.init(self)

	gridview:setNumberOfSections(#levelData['puzzles']['categories'])
	local numRows = 0
	for i=1, #levelData['puzzles']['categories'] do 
		local calcRows = math.ceil(#levelData['puzzles']['categories'][i]['puzzles']/3)
		gridview:setNumberOfRowsInSection(i, calcRows)
		numRows += calcRows
	end 	
	gridview:setNumberOfColumns(3)	
	gridview:setSectionHeaderHeight(14)
	gridview:setContentInset(1, 4, 1, 4)
	gridview:setCellPadding(4, 8, 10, 4)
	gridview.changeRowOnColumnWrap = false
	
	active = true
end

function LevelSelect:start() 
	gridview:setSelection(1,1,1)
	gridview:scrollCellToCenter(1,1,1,false)
end 

function LevelSelect:update() 
	gfx.setFont(blockyFont)
	gfx.clear()	
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)             
	gridview:drawInRect(20, 20, 180, 200)
	gfx.setDitherPattern(0.5,gfx.image.kDitherTypeDiagonalLine)             
	gfx.setLineWidth(0)
	-- gfx.drawLine(20,20,150,20)
	gfx.drawLine(20,220,150,220)
	-- gfx.drawRect(20,20,180,200)
	
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)    
	local width = 200
	local height = 140        
	local infox = 200 
	local infoy = 0	
	gfx.drawRect(infox,-1,width,240)
	
	
	-- draw info pane
	
	local section, row, column = gridview:getSelection()
	puzzleData = levelData['puzzles']['categories'][section]['puzzles'][(row-1)*gridview:getNumberOfColumns() + column]
	
	if puzzleData then 
		
		local puzzle = getPuzzle(section,row,column)

		if  isPuzzleCleared(puzzleData['id']) then 	
			gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)

			local heightRatio = puzzle.totalWidth / puzzle.totalHeight
   			local constrainedDimension = heightRatio > 1.0 and width or height
			   
			local puzzleTotalPixelWidth = puzzle.totalWidth*puzzle:getPixelSizeForWidth(constrainedDimension)
			local puzzleTotalPixelHeight = puzzle.totalHeight*puzzle:getPixelSizeForWidth(constrainedDimension)

			puzzle:drawImage(infox + (width - puzzleTotalPixelWidth)/2.0, infoy + (height - puzzleTotalPixelHeight)/2.0, constrainedDimension)
		
			gfx.drawTextAligned(string.upper(puzzleData['name']), infox + width/2.0, 155.0, kTextAlignment.center)
	
			gfx.drawTextAligned("CLEARED: " .. getClearTimeString(puzzleData['id']), infox + width/2.0, 165.0, kTextAlignment.center)
	
		else 
			pixelsize = 12
			drawBlockText("?", infox + (width - 5*pixelsize)/2.0, infoy + (height - 5*pixelsize)/2.0, pixelsize)
			
			gfx.drawTextAligned("? ? ?", infox + width/2.0, 155.0, kTextAlignment.center)
		end 
		
		gfx.drawTextAligned(puzzle.totalWidth .. " X " .. puzzle.totalHeight, infox + width/2.0, 140.0, kTextAlignment.center)
	
		-- play button
		local rectWidth = 75
		gfx.drawRect(infox + width/2.0 - rectWidth/2.0, 185.0, rectWidth, 20.0)
		gfx.drawTextAligned("PLAY", infox + width/2.0, 190.0, kTextAlignment.center)
	end
	-- inputs
	if playdate.buttonJustPressed(playdate.kButtonUp) then 
		gridview:selectPreviousRow(false)
		local section, row, column = gridview:getSelection()
		if (row - 1) * gridview:getNumberOfColumns() + column > #levelData['puzzles']['categories'][section]['puzzles'] then 
			gridview:setSelection(section,row,1)
			gridview:scrollCellToCenter(section,row,1,true)
		end

	end 

	if playdate.buttonJustPressed(playdate.kButtonDown) then 
		gridview:selectNextRow(false)
		local section, row, column = gridview:getSelection()
		if (row - 1) * gridview:getNumberOfColumns() + column > #levelData['puzzles']['categories'][section]['puzzles'] then 
			gridview:setSelection(section,row,1)
			gridview:scrollCellToCenter(section,row,1,true)
		end
	end 

	if playdate.buttonJustPressed(playdate.kButtonLeft) then 
		gridview:selectPreviousColumn(false)
	end 

	if playdate.buttonJustPressed(playdate.kButtonRight) then 
		local section, row, column = gridview:getSelection()
		if (row - 1) * gridview:getNumberOfColumns() + column < #levelData['puzzles']['categories'][section]['puzzles'] then 				
			gridview:selectNextColumn(false)
		end
	end 

	if playdate.buttonJustPressed(playdate.kButtonA) then 
		local section,row,column = gridview:getSelection()
		active = false
		local puzzle = getPuzzle(section,row,column)		
		goLoadLevel(puzzle)
	end 

	if playdate.buttonJustPressed(playdate.kButtonB) then 
		active = false
		goMainMenu()
	end 
end

function getPuzzle(section, row, column)
	if cachedPuzzles == nil then 
		cachedPuzzles = {} 
	end 
	
	if cachedPuzzles[section] == nil then 
		cachedPuzzles[section] = {} 
	end 
	
	if cachedPuzzles[section][row] == nil then 
		cachedPuzzles[section][row] = {} 
	end 
	
	if cachedPuzzles[section][row][column] == nil then 
		puzzleData = levelData['puzzles']['categories'][section]['puzzles'][(row-1)*gridview:getNumberOfColumns() + column]				
		local puzzle = Puzzle(puzzleData)
		cachedPuzzles[section][row][column] = puzzle
	end 
	
	return cachedPuzzles[section][row][column]
end 

function gridview:drawCell(section, row, column, selected, x, y, width, height)
	if (row - 1) * gridview:getNumberOfColumns() + column <= #levelData['puzzles']['categories'][section]['puzzles'] then 
		
		local puzzle = getPuzzle(section,row,column)
		local heightRatio = puzzle.totalWidth / puzzle.totalHeight	
		local constrainedDimension = heightRatio > 1.0 and width or height
		local puzzleTotalPixelWidth = puzzle.totalWidth*puzzle:getPixelSizeForWidth(constrainedDimension)
		local puzzleTotalPixelHeight = puzzle.totalHeight*puzzle:getPixelSizeForWidth(constrainedDimension)
		local adjustedXPos = x + (width - puzzleTotalPixelWidth)/2.0
		local adjustedYPos = y + (height - puzzleTotalPixelHeight)/2.0
	
		local borderScale = 1.05
		local margin = (borderScale - 1.0)*0.5

		if selected then
			gfx.setLineWidth(3)
		else
			gfx.setLineWidth(0)
		end
		
		gfx.drawRect(
			x,
			y,
			width*borderScale,
			height*borderScale
		)

		if isPuzzleCleared(puzzle.puzzleData['id']) then 
			gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
			puzzle:drawImage(adjustedXPos + margin*width, adjustedYPos + margin*height, constrainedDimension)
		else 				
			local blockTextSize = 8
			local totalSize = 5 * blockTextSize
			drawBlockText("?", x + (width - totalSize)/2.0, y + (height - totalSize)/2.0, blockTextSize)
		end
		
	end
end


function gridview:drawSectionHeader(section, x, y, width, height)
	gfx.drawText(string.upper(levelData['puzzles']['categories'][section]["id"]), x + 10, y + 8)
end



