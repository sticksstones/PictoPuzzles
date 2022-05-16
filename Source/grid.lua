import "CoreLibs/graphics"
import "CoreLibs/math"
import "CoreLibs/object"
import "CoreLibs/easing"
import "CoreLibs/animator"
import 'puzzle'
import 'save_funcs'
import 'funcs'

local gfx = playdate.graphics

class('Grid').extends()

gfx.setColor(gfx.kColorBlack)

local lastDirPressed = 0
local dirPressTimestamp = -1.0
local dirPressRepeatTimestamp = -1.0
local dirPressRepeatTime <const> = 100
local dirPressTimeTillRepeat <const> = 350
local setContinue = 0
local zoomLevel = 1.0

local cursorLocX = 0
local cursorLocY = 0

local kDefaultSpacing <const> = 16
local kLeftHandOffsetX <const> = 150
local kRightHandOffsetX <const> = 8
local kUpOffsetY <const> = 72
local kDownOffsetY <const> = 8

local kZoomOutSpacing <const> = 8
local kZoomOutOffsetX <const> = 64
local kZoomOutOffsetY <const> = 36

local spacing = 16
local offsetX = 128
local offsetY = 72

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()

local setVal = 0

local imageIndex = 1

local puzzle = nil
local matrix = nil
local imgmatrix = nil

local files = nil
local imageIndexChangedTimestamp = 0.0
local targetDrawOffsetX = 0.0
local targetDrawOffsetY = 0.0

local initialized = false

function Grid:init()
	 Grid.super.init(self)
end

function Grid:loadPuzzle(puzzleSelected)
	 puzzleComplete = false
	 initialized = false
	 puzzle = puzzleSelected
	 puzzle:generateHeaders()

	 self.matrices = table.create(#puzzle.imgmatrices,0)

	 for i=1, #puzzle.imgmatrices do
		 local thisMatrix = table.create(puzzle.pieceHeight)
		 for y = 0, puzzle.pieceHeight-1 do
			  thisMatrix[y] = table.create(puzzle.pieceWidth, 0)
			  for x = 0, puzzle.pieceWidth-1 do
					thisMatrix[y][x] = 0
			  end
		 end
		 table.insert(self.matrices, thisMatrix)
	 end

	 matrix = self.matrices[imageIndex]
	 imgmatrix = puzzle.imgmatrices[imageIndex]

	gfx.setFont(gridFont)

	puzzleFinishTimestamp = 0.0
	offsetX = kLeftHandOffsetX
	offsetY = kUpOffsetY
	spacing = kDefaultSpacing

    imageIndex = 1
	initTimestamp = playdate.getCurrentTimeMilliseconds()
	initialized = true
end

function Grid:isOnRightHandSide()
   local thisImageIndex = imageIndex
   local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth)

   return (column > 0 and column + 1 == puzzle.dimensionWidth)
end 

function Grid:isOnLowerSide()
   local thisImageIndex = imageIndex
   local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth)

   return (row > 0 and row + 1 == puzzle.dimensionHeight)
end 

function Grid:drawGrid(overrideImageIndex)
   local thisImageIndex = overrideImageIndex and overrideImageIndex or imageIndex
   local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth)
   local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth)
   local adjustedOffsetX = offsetX + (column * (puzzle.pieceWidth*spacing))
   local adjustedOffsetY = offsetY + (row * (puzzle.pieceHeight*spacing))

   gfx.setFont(gridFont)

   if imageIndex == thisImageIndex then 
	  gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
   else 
	  gfx.setDitherPattern(0.5,gfx.image.kDitherTypeVerticalLine)
   end 

   gfx.drawLine(adjustedOffsetX, adjustedOffsetY, adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY)

   gfx.drawLine(adjustedOffsetX, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing, adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing)

   -- draw row data
   local rowNum = 0
   for key,value in pairs(puzzle.rowData[thisImageIndex]) do
		
	  -- draw grid lines
	  if rowNum >= 1 then
		 if rowNum % 5 == 0 and thisImageIndex == imageIndex or zoom < 1.0  then
			gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
		 elseif thisImageIndex == imageIndex then 
			gfx.setDitherPattern(0.5,gfx.image.kDitherTypeVerticalLine)
		 else
			gfx.setDitherPattern(0.75,gfx.image.kDitherTypeVerticalLine)
		 end

		 gfx.drawLine(
			adjustedOffsetX, 
			adjustedOffsetY + rowNum * spacing - 1, 
			adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, 
			adjustedOffsetY + rowNum * spacing - 1
		 )
	  end

	  -- draw grid labels
	  if zoom >= 1.0 and thisImageIndex == imageIndex then
		 local drawStr = ""
		 
		 for key2,value2 in pairs(value) do
			drawStr = drawStr .. " " .. value2
		 end

		 if cursorLocY == rowNum then
			gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
			gfx.setColor(gfx.kColorBlack)

			if self:isOnRightHandSide() then 
			   gfx.fillRect(adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY + rowNum * spacing, 999, spacing)
			   
			   gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			   
			   gfx.drawTextAligned(drawStr, adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY + rowNum * spacing + 2, kTextAlignment.left)
			   gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)

			else 
			   gfx.setColor(gfx.kColorBlack)
			   gfx.fillRect(0, adjustedOffsetY + rowNum * spacing, adjustedOffsetX, spacing)
			   
			   gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			   
			   gfx.drawTextAligned(drawStr, adjustedOffsetX - 4, adjustedOffsetY + rowNum * spacing + 2, kTextAlignment.right)
			   gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
		 
			end
		 else
			if self:isOnRightHandSide() then 
			   gfx.drawTextAligned(drawStr, adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY + rowNum * spacing + 2, kTextAlignment.left)
			else 
			   gfx.drawTextAligned(drawStr, adjustedOffsetX - 4, adjustedOffsetY + rowNum * spacing + 2, kTextAlignment.right)
			end
		 end
	  end


	  rowNum += 1
   end

   if imageIndex == thisImageIndex then 
	  gfx.setDitherPattern(0.0,gfx.image.kDitherTypeHorizontalLine)
   else 
	  gfx.setDitherPattern(0.5,gfx.image.kDitherTypeHorizontalLine)
   end 

   gfx.drawLine(adjustedOffsetX, adjustedOffsetY, adjustedOffsetX, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing)

   gfx.drawLine(adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY, adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing)


   -- draw col data
   local colNum = 0
   local maxColVals = 6
   
   for key,value in pairs(puzzle.colData[thisImageIndex]) do

	  -- draw grid lines
	  if colNum >= 1 then
		 if colNum % 5 == 0 and thisImageIndex == imageIndex or zoom < 1.0 then
			gfx.setDitherPattern(0.0,gfx.image.kDitherTypeHorizontalLine)
		 elseif thisImageIndex == imageIndex then 
			gfx.setDitherPattern(0.5,gfx.image.kDitherTypeHorizontalLine)
		 else
			gfx.setDitherPattern(0.75,gfx.image.kDitherTypeHorizontalLine)
		 end

		 gfx.drawLine(
			adjustedOffsetX + colNum * spacing - 1, 
			adjustedOffsetY, 
			adjustedOffsetX + colNum * spacing - 1,
			adjustedOffsetY  + #puzzle.rowData[thisImageIndex] * spacing
		 )
	  end

	  -- draw grid labels
	  if zoom >= 1.0 and thisImageIndex == imageIndex then
		 local drawStr = ""
		 
		 local horizExtraOffset = 2
		 
		 if #value < maxColVals and not self:isOnLowerSide() then
			for i = 0, 4 - #value do               
			   drawStr = drawStr .. "\n"
			end
		 end
		 
		 for key2,value2 in pairs(value) do
			if value2 > 9 then 
			  horizExtraOffset = 0
			end
			drawStr = drawStr .. "\n" .. value2
		 end


		if cursorLocX == colNum then
			 gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
			 gfx.setColor(gfx.kColorBlack)
		   if self:isOnLowerSide() then 
			  gfx.fillRect(adjustedOffsetX + colNum * spacing, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing, spacing, 999)
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			   gfx.drawTextAligned(drawStr, adjustedOffsetX + colNum * spacing + horizExtraOffset, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - 9, kTextAlignment.centered)
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
		   else 
			  gfx.fillRect(adjustedOffsetX + colNum * spacing, 0, spacing, adjustedOffsetY)
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			  gfx.drawTextAligned(drawStr, adjustedOffsetX + colNum * spacing + horizExtraOffset, 12 + adjustedOffsetY - spacing*maxColVals, kTextAlignment.centered)
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)   
		  end 

		else
		  if self:isOnLowerSide() then 
			   gfx.drawTextAligned(drawStr, adjustedOffsetX + colNum * spacing + horizExtraOffset, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - 9, kTextAlignment.centered)
		  else 
			gfx.drawTextAligned(drawStr, adjustedOffsetX + colNum * spacing + horizExtraOffset, 12 + adjustedOffsetY - spacing*maxColVals, kTextAlignment.centered)

		  end 
				end
		end

		 colNum += 1
	 end
end

function Grid:drawPlayerImage(overrideImageIndex)
   local thisImageIndex = overrideImageIndex and overrideImageIndex or imageIndex
   local thisMatrix = self.matrices[thisImageIndex]
   local thisImgMatrix = puzzle.imgmatrices[thisImageIndex]
   local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth)
   local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth)
   local adjustedOffsetX = offsetX + (column * (puzzle.pieceWidth*spacing))
   local adjustedOffsetY = offsetY + (row * (puzzle.pieceHeight*spacing))

	local matrixCompleted = true

	 for y= 0, #thisMatrix
	 do
		  for x= 0, #thisMatrix[y]
		  do
				if thisImgMatrix[y][x] == 1 and thisMatrix[y][x] ~= 1
					 or thisImgMatrix[y][x] == 0 and thisMatrix[y][x] == 1 then
					 matrixCompleted = false
				end

		if thisImageIndex == imageIndex or puzzleComplete then 
				  if thisMatrix[y][x] == 1 then
					   gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
					   gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
				  elseif thisMatrix[y][x] == -1 and not puzzleComplete then
					   gfx.setDitherPattern(0.5,gfx.image.kDitherTypeDiagonalLine)
					   gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
				  end
		else 
		  if thisMatrix[y][x] == 1 then
		   gfx.setDitherPattern(0.5,gfx.image.kDitherTypeBayer8x8)
		   gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
		elseif thisMatrix[y][x] == -1 and not puzzleComplete then
		   -- gfx.setDitherPattern(0.75,gfx.image.kDitherTypeBayer2x2)
		   gfx.setDitherPattern(0.75,gfx.image.kDitherTypeDiagonalLine)
		   gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
		end

		end 
		  end
	 end

	 gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
end

function Grid:drawCursor()
   local thisImageIndex = imageIndex
   local thisMatrix = self.matrices[thisImageIndex]   
   local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth)
   local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth)
   local adjustedOffsetX = offsetX + (column * (puzzle.pieceWidth*spacing))
   local adjustedOffsetY = offsetY + (row * (puzzle.pieceHeight*spacing))

   gfx.setLineWidth(1)
   gfx.setDitherPattern(0.0,gfx.image.kDitherTypeBayer2x2)
  if thisMatrix[cursorLocY][cursorLocX] == 1 or thisMatrix[cursorLocY][cursorLocX] == -1
	then
	 gfx.setColor(gfx.kColorWhite)
   else
	 gfx.setColor(gfx.kColorBlack)
   end
   gfx.setColor(gfx.kColorXOR)
   local t = playdate.getCurrentTimeMilliseconds()/1000.0
   local loopDuration = t % 2.0
   local radius = 1.0
   if loopDuration > 1.0 then 
	 loopDuration -= 1.0
	loopDuration = 1.0 - loopDuration
  end 
  
  radius = playdate.easingFunctions.inOutElastic(loopDuration, 3.0, 6.0, 2.0)
   
   gfx.drawCircleAtPoint(adjustedOffsetX + spacing*cursorLocX + spacing*0.5 , adjustedOffsetY + spacing*cursorLocY + spacing*0.5, radius )
  gfx.setColor(gfx.kColorBlack)
end

function Grid:updateCursor()
	 newCellTarget = false
	 currTime = playdate.getCurrentTimeMilliseconds()
   local thisMatrix = self.matrices[imageIndex]   

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

	 if cursorLocX >= #puzzle.colData[imageIndex] then
		  cursorLocX = 0
	 elseif cursorLocX < 0 then
		  cursorLocX = #puzzle.colData[imageIndex] - 1
	 end

	 if cursorLocY >= #puzzle.rowData[imageIndex] then
		  cursorLocY = 0
	 elseif cursorLocY < 0 then
		  cursorLocY = #puzzle.rowData[imageIndex] - 1
	 end

	 if playdate.buttonJustPressed(playdate.kButtonA) then
		  newCellTarget = true
		  setContinue = 0

		  if thisMatrix[cursorLocY][cursorLocX] ~= 1 then
				setVal = 1
		  else
				setVal = 0
		  end
	 elseif playdate.buttonJustPressed(playdate.kButtonB) then
		  newCellTarget = true

		  if thisMatrix[cursorLocY][cursorLocX] ~= -1 then
				setVal = -1
		  else
				setVal = 0
		  end
	 end

	 if (playdate.buttonIsPressed(playdate.kButtonA) or playdate.buttonIsPressed(playdate.kButtonB)) and newCellTarget then
		 thisMatrix[cursorLocY][cursorLocX] = setVal
		 notifyGridChanged()
		 if setVal == 1 then
			  synth:playNote(60+setContinue*20, 1, 0.033)
			  setContinue += 1
		 elseif setVal == -1 then
			  noiseSynth:playNote(60, 0.5, 0.016)
		 end
	 end
end

function Grid:checkCrank()
   local crankPos = playdate.getCrankPosition()
   
   local crankRangeUpper = 330.0
   local crankRangeLower = 220.0
   local backDeadZone = 150.0

  if crankPos < backDeadZone then 
	  crankPos = crankRangeUpper
  elseif crankPos > crankRangeUpper then 
	 crankPos = crankRangeUpper
  elseif crankPos < crankRangeLower then 
	crankPos = crankRangeLower
  end 
   
   crankPos = math.max(0.0, math.min(1.0 - (crankRangeUpper - crankPos)/(crankRangeUpper- crankRangeLower),1.0))

  zoom = crankPos

   local row = math.floor((imageIndex-1) / puzzle.dimensionWidth)
   local column = math.floor((imageIndex-1) % puzzle.dimensionWidth)
  
   targetDrawOffsetX = -1 * (column) * puzzle.pieceWidth*spacing
   targetDrawOffsetY = -1 * (row) * puzzle.pieceHeight*spacing

  
   if self:isOnRightHandSide() then 
	  offsetX = playdate.math.lerp(kRightHandOffsetX, kZoomOutOffsetX, 1.0 - zoom)
   else 
	  offsetX = playdate.math.lerp(kLeftHandOffsetX, kZoomOutOffsetX, 1.0 - zoom)
   end 
   
   if self:isOnLowerSide() then 
	  offsetY = playdate.math.lerp(kDownOffsetY, kZoomOutOffsetY, 1.0 - zoom)
   else 
	  offsetY = playdate.math.lerp(kUpOffsetY, kZoomOutOffsetY, 1.0 - zoom)
   end 
   spacing = playdate.math.lerp(kDefaultSpacing, kZoomOutSpacing, 1.0 -zoom)
end

function updateDrawOffset()   
	local drawOffsetX, drawOffsetY = gfx.getDrawOffset()
	drawOffsetX = playdate.math.lerp(drawOffsetX, targetDrawOffsetX, 0.5)
	drawOffsetY = playdate.math.lerp(drawOffsetY, targetDrawOffsetY, 0.5)
	
   gfx.setDrawOffset(drawOffsetX,drawOffsetY)
end 


function Grid:updateBoardCursor()
   local thisImageIndex = imageIndex
   local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth) + 1
   local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth) + 1 

   if playdate.buttonJustPressed(playdate.kButtonRight) then 
	  if column < puzzle.dimensionWidth then 
		 column += 1
	  end 
   end 

   if playdate.buttonJustPressed(playdate.kButtonLeft) then 
	  if column > 1 then 
		 column -= 1
	  end      
   end 

   if playdate.buttonJustPressed(playdate.kButtonUp) then 
	  if row > 1 then 
		 row -= 1
	  end
   end 

   if playdate.buttonJustPressed(playdate.kButtonDown) then 
	  if row < puzzle.dimensionHeight then 
		 row += 1
	  end 
   end

   local newImageIndex = (row - 1) * puzzle.dimensionWidth + column 
   
   if newImageIndex ~= imageIndex then 
	  imageIndex = newImageIndex
	  imageIndexChangedTimestamp = playdate.getCurrentTimeMilliseconds()
   end
end 

function Grid:drawBoardCursor() 
   gfx.setColor(gfx.kColorBlack)
   gfx.setDitherPattern(0.5,gfx.image.kDitherTypeBayer2x2)
   gfx.setLineWidth(8)

   local thisImageIndex = imageIndex
   local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth)
   local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth)
   local adjustedOffsetX = offsetX + (column * (puzzle.pieceWidth*spacing))
   local adjustedOffsetY = offsetY + (row * (puzzle.pieceHeight*spacing))

   gfx.drawRect(adjustedOffsetX, adjustedOffsetY, puzzle.pieceWidth*spacing, puzzle.pieceHeight*spacing)
   gfx.setLineWidth(1)
end 

function Grid:updatePuzzleComplete()
	puzzleComplete = true
	offsetX = playdate.math.lerp(offsetX, (screenWidth - (spacing*puzzle.totalWidth))/2.0, math.min(1.0,(playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp)/1000.0))
 	offsetY = playdate.math.lerp(offsetY,  (screenHeight - 20 - (spacing*puzzle.totalHeight))/2.0, math.min(1.0, (playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp)/1000.0))
 	
 	local heightRatio = math.floor((screenHeight - 20)/puzzle.totalHeight)
 	local widthRatio = math.floor(screenWidth/puzzle.totalWidth)
 	if widthRatio < heightRatio then 
		fitSpacing = math.min(kDefaultSpacing, widthRatio)
 	else 
		fitSpacing = math.min(kDefaultSpacing, heightRatio)
	end
 	spacing = playdate.math.lerp(spacing, fitSpacing, math.min(1.0, (playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp)/1000.0))
 	targetDrawOffsetX = 0.0
 	targetDrawOffsetY = 0.0

	for i = 1, #self.matrices do 
	  self:drawPlayerImage(i)
    end

	gfx.setFont(blockyFont)
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
	gfx.drawTextAligned("COMPLETED IN " .. getClearTimeString(puzzle.puzzleData['id']), 0.5*screenWidth, screenHeight - (screenHeight-spacing*puzzle.totalHeight)/2.0, kTextAlignment.center)

	updateDrawOffset()
end

function Grid:update()
   if initialized and playdate.getCurrentTimeMilliseconds() - initTimestamp > 100 then
	  	gfx.clear()
 		self:checkCrank()		 
 		for i = 1, #self.matrices do 
			self:drawGrid(i)
 		end
	
 		for i = 1, #self.matrices do 
			self:drawPlayerImage(i)
 		end
	
 		if zoom >= 1.0 then
			self:updateCursor()
			self:drawCursor()
 		else
			self:updateBoardCursor()
			self:drawBoardCursor()
 		end
  		updateDrawOffset()
	end
end



