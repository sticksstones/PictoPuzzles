import "CoreLibs/graphics"
import "CoreLibs/object"
import 'puzzle'

local gfx = playdate.graphics

class('Game').extends()

gfx.setColor(gfx.kColorBlack)

local lastDirPressed = 0
local dirPressTimestamp = -1.0
local dirPressRepeatTimestamp = -1.0
local dirPressRepeatTime = 100
local dirPressTimeTillRepeat = 350

local cursorLocX = 0
local cursorLocY = 0
local spacing = 16
local offsetX = 128
local offsetY = 72

local setVal = 0

local puzzle = nil
local matrix = nil

local files = nil

local initialized = false

function Game:init(puzzleData)
	Game.super.init(self)
end

function Game:loadPuzzle(puzzleData) 
	puzzle = Puzzle(puzzleData)
	
	matrix = table.create(#puzzle.colData, 0)
	for y = 0, #puzzle.colData do 
		matrix[y] = table.create(#puzzle.rowData, 0)
		for x = 0, #puzzle.rowData do 
			matrix[y][x] = 0
		end
	end 
		
	-- load font
   local gridFont = gfx.font.new('assets/Picross-Small')
   gridFont:setTracking(0)
   gridFont:setLeading(4)
   gfx.setFont(gridFont)
   initTimestamp = playdate.getCurrentTimeMilliseconds()
   initialized = true	
	
end

function Game:drawGrid() 
	gfx.drawLine(offsetX, offsetY, offsetX + #puzzle.colData * spacing, offsetY)
	-- draw row data
	local rowNum = 0
	for key,value in pairs(puzzle.rowData) do
		local drawStr = ""
		for key2,value2 in pairs(value) do 
			drawStr = drawStr .. " " .. value2 
		end 
	   if rowNum >= 1 then
		  if rowNum % 5 == 0 then
		   gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)             
		  else 
		   gfx.setDitherPattern(0.5,gfx.image.kDitherTypeVerticalLine)             
		end
		  -- end
		   gfx.drawLine(offsetX, offsetY + rowNum * spacing - 1, offsetX + #puzzle.colData * spacing, offsetY + rowNum * spacing - 1)
	   end
	   
	   if cursorLocY == rowNum then 
		  gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
		  gfx.setColor(gfx.kColorBlack)
		  gfx.fillRect(0, offsetY + rowNum * spacing - 2, offsetX, spacing)
		  gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
		  gfx.drawTextAligned(drawStr, offsetX - 4, offsetY + rowNum * spacing, kTextAlignment.right)
				 
	   else 
		  gfx.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
		  gfx.drawTextAligned(drawStr, offsetX - 4, offsetY + rowNum * spacing, kTextAlignment.right)                    
	   end 
	   
	   rowNum += 1
	end
		
	gfx.drawLine(offsetX, offsetY, offsetX, offsetY + #puzzle.rowData * spacing)
	-- draw col data
	local colNum = 0
	local maxColVals = 6
	for key,value in pairs(puzzle.colData) do
		local drawStr = "" 
	
		if #value < maxColVals then 
			for i = 0, 4 - #value do
				drawStr = drawStr .. "\n"
			end
		end 
		
		for key2,value2 in pairs(value) do 
			drawStr = drawStr .. "\n" .. value2 
		end 
		if colNum >= 1 then
			  if colNum % 5 == 0 then
				 gfx.setDitherPattern(0.0,gfx.image.kDitherTypeHorizontalLine)             
			  else 
				gfx.setDitherPattern(0.5,gfx.image.kDitherTypeHorizontalLine)             
			  end
			   
			   gfx.drawLine(offsetX + colNum * spacing - 1, offsetY, offsetX + colNum * spacing - 1, offsetY  + #puzzle.rowData * spacing)
		end
		
		if cursorLocX == colNum then 
			gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
			gfx.setColor(gfx.kColorBlack)
			gfx.fillRect(offsetX + colNum * spacing, 0, spacing, offsetY)
			gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			 gfx.drawTextAligned(drawStr, offsetX + colNum * spacing + 2, 10 + offsetY - spacing*maxColVals, kTextAlignment.centered)
				   
		 else 
			gfx.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
			 gfx.drawTextAligned(drawStr, offsetX + colNum * spacing + 2, 10 + offsetY - spacing*maxColVals, kTextAlignment.centered)
					  
		 end 

	
	   colNum += 1
	end
end

function Game:drawPlayerImage() 

	for y= 0, #matrix
	do
		for x= 0, #matrix[y]
		do            
			if matrix[y][x] == 1 then 
				gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
				gfx.fillRect(offsetX + spacing*x, offsetY + spacing*y, spacing-1, spacing-1)
			elseif matrix[y][x] == -1 then 
				gfx.setDitherPattern(0.5,gfx.image.kDitherTypeDiagonalLine)
				gfx.fillRect(offsetX + spacing*x, offsetY + spacing*y, spacing-1, spacing-1)
			end


		end
	end
	
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)

end

function Game:drawCursor() 
   if matrix[cursorLocY][cursorLocX] == 1 then 
	  gfx.setColor(gfx.kColorWhite)  
   else 
	  gfx.setColor(gfx.kColorBlack)  
   end 
	gfx.setDitherPattern(0.5,gfx.image.kDitherTypeBayer2x2)
	gfx.setLineWidth(4)
	gfx.drawRect(offsetX + spacing*cursorLocX - 1, offsetY + spacing*cursorLocY - 1, spacing+1, spacing+1)
	gfx.setLineWidth(1)

end

function Game:updateCursor() 
	newCellTarget = false
	currTime = playdate.getCurrentTimeMilliseconds()
	
	if not playdate.buttonIsPressed(playdate.kButtonRight)
	   and not playdate.buttonIsPressed(playdate.kButtonDown)
	   and not playdate.buttonIsPressed(playdate.kButtonLeft)
	   and not playdate.buttonIsPressed(playdate.kButtonUp)
	   then 
		lastDirPressed = 0       
	end
	
	if playdate.buttonIsPressed(playdate.kButtonRight) and
	   currTime > dirPressRepeatTimestamp and lastDirPressed == playdate.kButtonRight or
	   playdate.buttonJustPressed(playdate.kButtonRight) then 
		newCellTarget = true 
		lastDirPressed = playdate.kButtonRight
		if playdate.buttonJustPressed(playdate.kButtonRight) then 
			dirPressRepeatTimestamp = currTime + dirPressTimeTillRepeat
		else 
			dirPressRepeatTimestamp = currTime + dirPressRepeatTime
		end 
		cursorLocX += 1
	elseif playdate.buttonIsPressed(playdate.kButtonLeft) and currTime > dirPressRepeatTimestamp and lastDirPressed == playdate.kButtonLeft or playdate.buttonJustPressed(playdate.kButtonLeft) then 
		newCellTarget = true 
		lastDirPressed = playdate.kButtonLeft
		if playdate.buttonJustPressed(playdate.kButtonLeft) then 
			dirPressRepeatTimestamp = currTime + dirPressTimeTillRepeat
		else 
			dirPressRepeatTimestamp = currTime + dirPressRepeatTime
		end 
		cursorLocX -= 1
	elseif playdate.buttonIsPressed(playdate.kButtonUp) and currTime > dirPressRepeatTimestamp and lastDirPressed == playdate.kButtonUp or playdate.buttonJustPressed(playdate.kButtonUp) then        
		newCellTarget = true 
		lastDirPressed = playdate.kButtonUp
		if playdate.buttonJustPressed(playdate.kButtonUp) then 
			dirPressRepeatTimestamp = currTime + dirPressTimeTillRepeat
		else 
			dirPressRepeatTimestamp = currTime + dirPressRepeatTime
		end 
		cursorLocY -= 1
	elseif playdate.buttonIsPressed(playdate.kButtonDown) and currTime > dirPressRepeatTimestamp and lastDirPressed == playdate.kButtonDown or playdate.buttonJustPressed(playdate.kButtonDown) then 
		newCellTarget = true 
		lastDirPressed = playdate.kButtonDown
		if playdate.buttonJustPressed(playdate.kButtonDown) then 
			dirPressRepeatTimestamp = currTime + dirPressTimeTillRepeat
		else 
			dirPressRepeatTimestamp = currTime + dirPressRepeatTime
		end 
		cursorLocY += 1
	end
	
	if cursorLocX >= #puzzle.colData then 
		cursorLocX = 0
	elseif cursorLocX < 0 then
		cursorLocX = #puzzle.colData - 1
	end 
	
	if cursorLocY >= #puzzle.rowData then 
		cursorLocY = 0
	elseif cursorLocY < 0 then 
		cursorLocY = #puzzle.rowData - 1
	end 
	
	if playdate.buttonJustPressed(playdate.kButtonA) then 
		newCellTarget = true 
		
		if matrix[cursorLocY][cursorLocX] ~= 1 then 
			setVal = 1            
		else 
			setVal = 0
		end
	elseif playdate.buttonJustPressed(playdate.kButtonB) then 
		newCellTarget = true 
		
		if matrix[cursorLocY][cursorLocX] ~= -1 then 
			setVal = -1            
		else 
			setVal = 0
		end
	end     

	if (playdate.buttonIsPressed(playdate.kButtonA) or playdate.buttonIsPressed(playdate.kButtonB)) and newCellTarget then 
	   matrix[cursorLocY][cursorLocX] = setVal
	end 
end 

-- init
-- baseInit()

function Game:update()
	if initialized and playdate.getCurrentTimeMilliseconds() - initTimestamp > 100 then
		gfx.clear()
		self:drawGrid()
		self:updateCursor()
		self:drawPlayerImage()
		self:drawCursor()
	end 
	-- drawImage()
end



