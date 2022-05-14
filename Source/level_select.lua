import 'CoreLibs/ui/gridview.lua'
import 'CoreLibs/nineslice'
import "CoreLibs/graphics"
import "CoreLibs/object"
import 'puzzle'
import 'blocktext'

local gfx = playdate.graphics

local selectedGrid = 0

local gridFont = gfx.font.new('assets/blocky')
gridFont:setTracking(1)

local gridview = playdate.ui.gridview.new(50, 50)
local active = false

local levelData = json.decodeFile(playdate.file.open('assets/puzzles/puzzles.json'))

class('LevelSelect').extends()

function LevelSelect:init() 
	LevelSelect.super.init(self)

	-- gridview.backgroundImage = playdate.graphics.nineSlice.new('assets/shadowbox', 4, 4, 45, 45)
	-- gridview:setNumberOfColumns(#levelData['puzzles'])
	gridview:setNumberOfSections(#levelData['puzzles']['categories']) -- number of sections is set automatically

	local numRows = 0
	for i=1, #levelData['puzzles']['categories'] do 
		local calcRows = math.ceil(#levelData['puzzles']['categories'][i]['puzzles']/3)
		gridview:setNumberOfRowsInSection(i, calcRows)
		numRows += calcRows
	end 	
	gridview:setNumberOfColumns(3)	
	gridview:setSectionHeaderHeight(28)
	gridview:setContentInset(1, 4, 1, 4)
	gridview:setCellPadding(4, 4, 4, 4)
	gridview.changeRowOnColumnWrap = false
	active = true
end

function LevelSelect:start() 
	gridview:setSelection(1,1,1)
	gridview:scrollCellToCenter(1,1,1,false)
end 

function LevelSelect:update() 
	gfx.setFont(gridFont)
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
	local height = 200        
	local infox = 200 
	local infoy = -30 		
	gfx.drawRect(infox,-1,width,240)
	
	
	-- draw info pane
	
	local section, row, column = gridview:getSelection()
	puzzleData = levelData['puzzles']['categories'][section]['puzzles'][(row-1)*column + column]
	
	if puzzleData then 
		local img =  gfx.image.new('assets/puzzles/images/' .. puzzleData['image'])  
		
		if isPuzzleCleared(puzzleData['id']) then 	
			gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
   			
		
			local pixelsize = 12
			for imgy= 0, img.height-1
			do
				for imgx= 0, img.width-1
				do
					sample = img:sample(imgx,imgy)
					if sample == gfx.kColorBlack then
						gfx.fillRect(infox + (width - img.width*pixelsize)/2.0 + pixelsize*imgx, infoy + (height - img.height*pixelsize)/2.0 + pixelsize*imgy, pixelsize-1, pixelsize-1)
					end 
				end
			end
			
			gfx.drawTextAligned(string.upper(puzzleData['name']), infox + width/2.0, 150.0, kTextAlignment.center)
	
			gfx.drawTextAligned(getClearTimeString(puzzleData['id']), infox + width/2.0, 160.0, kTextAlignment.center)
	
		else 
			pixelsize = 12
			drawBlockText("?", infox + (width - 5*pixelsize)/2.0, infoy + (height - 5*pixelsize)/2.0, pixelsize)
			
			gfx.drawTextAligned("? ? ?", infox + width/2.0, 150.0, kTextAlignment.center)
		end 
		
		gfx.drawTextAligned(img.width .. " X " .. img.height, infox + width/2.0, 135.0, kTextAlignment.center)
	
		-- play button
		local rectWidth = 75
		gfx.drawRect(infox + width/2.0 - rectWidth/2.0, 185.0, rectWidth, 20.0)
		gfx.drawTextAligned("PLAY", infox + width/2.0, 190.0, kTextAlignment.center)
	end
	-- inputs
	if playdate.buttonJustPressed(playdate.kButtonUp) then 
		gridview:selectPreviousRow(false)
		local section, row, column = gridview:getSelection()
		if (row - 1) * column + column > #levelData['puzzles']['categories'][section]['puzzles'] then 
			gridview:setSelection(section,row,1)
			-- gridview:selectPreviousColumn(false)
		end

	end 

	if playdate.buttonJustPressed(playdate.kButtonDown) then 
		gridview:selectNextRow(false)
		local section, row, column = gridview:getSelection()
		if (row - 1) * column + column > #levelData['puzzles']['categories'][section]['puzzles'] then 
			gridview:setSelection(section,row,1)
			-- gridview:selectPreviousColumn(false)
		end
	end 

	if playdate.buttonJustPressed(playdate.kButtonLeft) then 
		gridview:selectPreviousColumn(false)
	end 

	if playdate.buttonJustPressed(playdate.kButtonRight) then 
		local section, row, column = gridview:getSelection()
		if (row - 1) * column + column < #levelData['puzzles']['categories'][section]['puzzles'] then 				
			gridview:selectNextColumn(false)
		end
	end 

	if playdate.buttonJustPressed(playdate.kButtonA) then 
		local section,row,column = gridview:getSelection()
		active = false
		puzzleData = levelData['puzzles']['categories'][section]['puzzles'][(row-1)*column + column]
		goLoadLevel(puzzleData)
	end 

	if playdate.buttonJustPressed(playdate.kButtonB) then 
		active = false
		goMainMenu()
	end 
end

function gridview:drawCell(section, row, column, selected, x, y, width, height)
	if (row - 1) * column + column <= #levelData['puzzles']['categories'][section]['puzzles'] then 
		if selected then
			gfx.setLineWidth(3)
			gfx.drawRect(x,y,width,height)
		else
			gfx.setLineWidth(0)
			gfx.drawRect(x,y,width,height)
		end
		
		
		puzzleData = levelData['puzzles']['categories'][section]['puzzles'][(row-1)*column + column]
		
		if isPuzzleCleared(puzzleData['id']) then 
			gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
	   	local img =  gfx.image.new('assets/puzzles/images/' .. puzzleData['image'])  
		
			local pixelsize = 3
			for imgy= 0, img.height-1
			do
				for imgx= 0, img.width-1
				do
					sample = img:sample(imgx,imgy)
					if sample == gfx.kColorBlack then
						gfx.fillRect(x + (width - img.width*pixelsize)/2.0 + pixelsize*imgx, y + (height - img.height*pixelsize)/2.0 + pixelsize*imgy, pixelsize-1, pixelsize-1)
					end 
				end
			end
		else 				
			drawBlockText("?", x+7, y+6, 7)
		end
		
	end
end


function gridview:drawSectionHeader(section, x, y, width, height)
	-- drawBlockText(levelData['puzzles']['categories'][section]["id"], x+7, y+6, 3)
	gfx.drawText(string.upper(levelData['puzzles']['categories'][section]["id"]), x + 10, y + 8)
end



