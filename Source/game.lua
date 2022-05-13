import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx = playdate.graphics

class('Game').extends()

gfx.setColor(gfx.kColorBlack)
lastDirPressed = 0
dirPressTimestamp = -1.0
dirPressRepeatTimestamp = -1.0
dirPressRepeatTime = 100
dirPressTimeTillRepeat = 350

cursorLocX = 0
cursorLocY = 0
spacing = 16
offsetX = 128
offsetY = 72

setVal = 0

rowData = {}
colData = {}
matrix = {} 

files = {}

function Game:init()
	Game.super.init(self)
end

function Game:baseInit() 
   -- load font
   local gridFont = gfx.font.new('assets/Picross-Small')
   gridFont:setTracking(0)
   gridFont:setLeading(4)
   gfx.setFont(gridFont)
   
   -- load puzzle
   self:loadPuzzles()
   math.randomseed(playdate.getSecondsSinceEpoch())
   fileIndex = math.random(1,#files)
   self:loadPuzzle(fileIndex)   

end 

function Game:loadPuzzles()
   files = playdate.file.listFiles('assets/puzzles/')
end

function Game:loadPuzzle(fileIndex)
   img = gfx.image.new('assets/puzzles/'..files[fileIndex])  
	
   -- get row data
   for y= 0, img.height-1
   do
	   rowIndex = y+1
	   rowCount = 0
	   rowData[rowIndex] = {}
	   matrix[y] = {} 
	   for x= 0, img.width-1
	   do
		   matrix[y][x] = 0
		   sample = img:sample(x,y)
		   
		   if sample == gfx.kColorBlack then
			   rowCount+= 1  
		   else
			   if rowCount > 0 then 
				   table.insert(rowData[rowIndex],rowCount)
				   rowCount = 0    
			   end 
		   end
	   end
   
	   if rowCount > 0 then 
		   table.insert(rowData[rowIndex],rowCount)
		   rowCount = 0    
	   end 
	   
	   if #rowData[rowIndex] == 0 then 
		   table.insert(rowData[rowIndex],0)
	   end 
   end
   
   -- get column data
   for x= 0, img.width-1
   do
	   colIndex = x+1
	   colCount = 0
	   colData[colIndex] = {}
	   for y= 0, img.height-1
	   do
		   sample = img:sample(x,y)
		   
		   if sample == gfx.kColorBlack then
			   colCount+= 1  
		   else
			   if colCount > 0 then 
				   table.insert(colData[colIndex],colCount)
				   colCount = 0    
			   end 
		   end
	   end
   
	   if colCount > 0 then 
		   table.insert(colData[colIndex],colCount)
		   colCount = 0    
	   end 
	   
	   
	   if #colData[colIndex] == 0 then 
		   table.insert(colData[colIndex],0)
	   end 
   end
end

function Game:drawGrid() 
	gfx.drawLine(offsetX, offsetY, offsetX + #colData * spacing, offsetY)
	-- draw row data
	rowNum = 0
	for key,value in pairs(rowData) do
		drawStr = ""
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
		   gfx.drawLine(offsetX, offsetY + rowNum * spacing - 1, offsetX + #colData * spacing, offsetY + rowNum * spacing - 1)
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
		
	gfx.drawLine(offsetX, offsetY, offsetX, offsetY + #rowData * spacing)
	-- draw col data
	colNum = 0
	maxColVals = 6
	for key,value in pairs(colData) do
		drawStr = "" 
	
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
			   
			   gfx.drawLine(offsetX + colNum * spacing - 1, offsetY, offsetX + colNum * spacing - 1, offsetY  + #rowData * spacing)
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

	for y= 0, img.height-1
	do
		for x= 0, img.width-1
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

function Game:drawImage() 
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)

	for y= 0, img.height-1
	do
		for x= 0, img.width-1
		do
			sample = img:sample(x,y)
			if sample == gfx.kColorBlack then
				gfx.fillRect(offsetX + spacing*x, offsetY + spacing*y, spacing-1, spacing-1)
			elseif sample == gfx.kColorWhite then
			end
		end
	end
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
	
	if cursorLocX >= #colData then 
		cursorLocX = 0
	elseif cursorLocX < 0 then
		cursorLocX = #colData - 1
	end 
	
	if cursorLocY >= #rowData then 
		cursorLocY = 0
	elseif cursorLocY < 0 then 
		cursorLocY = #rowData - 1
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
	gfx.clear()
	self:drawGrid()
	self:updateCursor()
	self:drawPlayerImage()
	self:drawCursor()
	-- drawImage()
end
