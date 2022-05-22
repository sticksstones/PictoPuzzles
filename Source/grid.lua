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

local cursorLocX = 0
local cursorLocY = 0

local zoom = 1.0

local kDefaultSpacing <const> = 32
local kLeftHandOffsetX <const> = 150
local kRightHandOffsetX <const> = 50
local kUpOffsetY <const> = 80
local kDownOffsetY <const> = 8

local kZoomOutSpacing <const> = 8
local kZoomOutOffsetX <const> = 64
local kZoomOutOffsetY <const> = 36

local maxZoom = 2.0
local maxSpacing = 32
local minSpacing = 8
local zoomOutMinSpacing = 2

local spacing = 16
local offsetX = 128
local offsetY = 72
local targetSpacing = 16
local targetOffsetX = 128
local targetOffsetY = 72

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

local headerRowImages = {}
local headerColumnImages = {}

local playerImages = {} 

local notePitch = 10

local gridSpaceAnimateTime = 125
local animateTillTimeStamp = 0

local fontSize <const> = 6

function Grid:init()
	 Grid.super.init(self)
end

function Grid:loadPuzzle(puzzleSelected)
	 puzzleComplete = false
	 initialized = false
	 puzzle = puzzleSelected
	 puzzle:generateHeaders()

	 self.matrices = table.create(#puzzle.imgmatrices,0)
	 self.matricesData = table.create(#puzzle.imgmatrices,0)
	 for i=1, #puzzle.imgmatrices do
	 	 local thisMatrix = table.create(puzzle.pieceHeight)
  		 local thisMatrixData = table.create(#thisMatrix)
 		 for y = 0, puzzle.pieceHeight-1 do
			  thisMatrix[y] = table.create(puzzle.pieceWidth, 0)
			  thisMatrixData[y] = table.create(#thisMatrix[y])
				  
  			  for x = 0, puzzle.pieceWidth-1 do
					thisMatrix[y][x] = 0
					thisMatrixData[y][x] = {} 
			  end
		 end
		 table.insert(self.matrices, thisMatrix)
		 table.insert(self.matricesData, thisMatrixData)
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

    for i=0, #headerRowImages do 
	  headerRowImages[i] = nil
  	end 

  	for i=0, #headerColumnImages do 
	  headerColumnImages[i] = nil
    end 

	for i=0, #playerImages do 
		playerImages[i] = nil
	end 

	targetSpacing = self:calculateIdealSpacing()
	minSpacing = 0.5*targetSpacing
	zoomOutMinSpacing = math.max(6, 0.5*minSpacing)
	zoom = self:getZoomForSpacing(targetSpacing)
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

   gfx.drawLine(adjustedOffsetX, adjustedOffsetY, adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing - 1, adjustedOffsetY)

   gfx.drawLine(adjustedOffsetX, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - 1, adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing - 1, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - 1)

   gfx.setColor(gfx.kColorBlack)
   gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy) 
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

		gfx.setColor(gfx.kColorBlack)
	  
	    if cursorLocY == rowNum then 
	  		if self:isOnRightHandSide() then 
			 	gfx.fillRect(adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing, adjustedOffsetY + rowNum * spacing, 999, spacing)
			else 
			   gfx.fillRect(0, adjustedOffsetY + rowNum * spacing, adjustedOffsetX, spacing)
			end 
		end

		local headerImage = headerRowImages[rowNum]
 	    if headerImage == nil or puzzle.headersNeedRedisplay == true then 
		 	local drawStr = ""
		 	
		 	for key2,value2 in pairs(value) do
				drawStr = drawStr .. " " .. value2
		 	end
			local textWidth, textHeight = gfx.getTextSize(drawStr)
			headerImage = gfx.image.new(textWidth, textHeight,playdate.graphics.kColorClear)
			headerRowImages[rowNum] = headerImage
			gfx.lockFocus(headerImage)
			gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
			gfx.setColor(gfx.kColorBlack)
 		    gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy) 
			if self:isOnRightHandSide() then 
				gfx.drawTextAligned(drawStr, 0, 0, kTextAlignment.left)	
			else 
				gfx.drawTextAligned(drawStr, textWidth - 3, 0, kTextAlignment.right)
		 	end
			gfx.unlockFocus()
		end 

		if cursorLocY == rowNum then
		  if self:isOnRightHandSide() then 
				 gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)				
				 headerImage:draw(adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing - 4, adjustedOffsetY + rowNum * spacing + (spacing - fontSize)/2.0)	 
				 gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy) 
		  else 
				 gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)			 
			     headerImage:draw(adjustedOffsetX  - headerImage.width, adjustedOffsetY + rowNum * spacing + (spacing - fontSize)/2.0)	 
				 gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)	   
		  end
	   else
		  if self:isOnRightHandSide() then 
		  	  headerImage:draw(adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing - 4, adjustedOffsetY + rowNum * spacing + (spacing - fontSize)/2.0)
		  else 
			  headerImage:draw(adjustedOffsetX - headerImage.width, adjustedOffsetY + rowNum  * spacing + (spacing - fontSize)/2.0)
		  end
	   end
	  rowNum += 1
   end

   if imageIndex == thisImageIndex then 
	  gfx.setDitherPattern(0.0,gfx.image.kDitherTypeHorizontalLine)
   else 
	  gfx.setDitherPattern(0.5,gfx.image.kDitherTypeHorizontalLine)
   end 

   gfx.drawLine(
   	adjustedOffsetX, 
   	adjustedOffsetY, 
   	adjustedOffsetX, 
   	adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - 1
   )

   gfx.drawLine(
   	adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing - 1, 
   	adjustedOffsetY, 
   	adjustedOffsetX + #puzzle.colData[thisImageIndex] * spacing - 1, 
   	adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - 1)
   end

   -- draw col data
   local colNum = 0
   local maxColVals = 8
   
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
			adjustedOffsetY  + #puzzle.rowData[thisImageIndex] * spacing - 1
		 )
	  end

	  -- draw grid labels
	  if zoom >= 1.0 and thisImageIndex == imageIndex then
		 gfx.setColor(gfx.kColorBlack)
	  	 gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)						   	
		 if cursorLocX == colNum then
		   if self:isOnLowerSide() then 
			gfx.fillRect(adjustedOffsetX + colNum * spacing, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing, spacing, 999)	
		   else
			gfx.fillRect(adjustedOffsetX + colNum * spacing, 0, spacing, adjustedOffsetY)
		   end 
		end 
		 
		local headerImage = headerColumnImages[colNum]
		if headerImage == nil or puzzle.headersNeedRedisplay == true then 		
		 	local drawStr = ""
		 	
		 	local horizExtraOffset = 2
		 	
		 	if #value < maxColVals and not self:isOnLowerSide() then
				for i = 0, (maxColVals - 1) - #value do               
			   	drawStr = drawStr .. "\n"
				end
		 	end
		 	
		 	for key2,value2 in pairs(value) do
				if value2 > 9 then 
			  	horizExtraOffset = 0
				end
				drawStr = drawStr .. "\n" .. value2
		 	end

			local textWidth, textHeight = gfx.getTextSize(drawStr)
			headerImage = gfx.image.new(textWidth+2, textHeight,playdate.graphics.kColorClear)
			headerColumnImages[colNum] = headerImage
			gfx.lockFocus(headerImage)
			gfx.drawTextAligned(drawStr, horizExtraOffset, 0, kTextAlignment.centered)
			gfx.unlockFocus()
		end

		if cursorLocX == colNum then
			 gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
			 gfx.setColor(gfx.kColorBlack)
		   if self:isOnLowerSide() then 
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			   headerImage:draw(adjustedOffsetX + colNum * spacing + (spacing - fontSize*2.0)/2.0, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - fontSize)
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
		   else 
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			  headerImage:draw(adjustedOffsetX + colNum * spacing + (spacing - fontSize*2.0)/2.0, -fontSize - 2 + adjustedOffsetY - ((fontSize+2)*(maxColVals+2)))
			  -- headerImage:draw(adjustedOffsetX + colNum * spacing + (spacing - fontSize*2.0)/2.0, adjustedOffsetY - (fontSize/2.0*maxColVals))
			  gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)   
		  end 
		
		else
			  if self:isOnLowerSide() then 
				   headerImage:draw(adjustedOffsetX + colNum * spacing + (spacing - fontSize*2.0)/2.0, adjustedOffsetY + #puzzle.rowData[thisImageIndex] * spacing - fontSize)
			  else 
				headerImage:draw(adjustedOffsetX + colNum * spacing + (spacing - fontSize*2.0)/2.0, -fontSize - 2 + adjustedOffsetY - ((fontSize+2)*(maxColVals+2)))		
			  end 
		end
	  end 
	colNum += 1
	 end

end

function Grid:drawPlayerImage(overrideImageIndex)
   local thisImageIndex = overrideImageIndex and overrideImageIndex or imageIndex
   local thisMatrix = self.matrices[thisImageIndex]
   local thisMatrixData = self.matricesData[thisImageIndex]
   local thisImgMatrix = puzzle.imgmatrices[thisImageIndex]
   local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth)
   local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth)
   local adjustedOffsetX = offsetX + (column * (puzzle.pieceWidth*spacing))
   local adjustedOffsetY = offsetY + (row * (puzzle.pieceHeight*spacing))
	local matrixCompleted = true

	local playerImage = playerImages[thisImageIndex]
	if playerImage == nil or puzzleComplete or (playdate.getCurrentTimeMilliseconds() <= animateTillTimeStamp and thisImageIndex == imageIndex)  then 
		playerImage = gfx.image.new(spacing*(#thisMatrix[1]+1), spacing*(#thisMatrix+1), gfx.kColorClear)
		playerImages[thisImageIndex] = playerImage
		gfx.lockFocus(playerImage)
	 	for y= 0, #thisMatrix do
		  	for x= 0, #thisMatrix[y] do
	  			t = 1.0
			  	if thisMatrixData[y][x]["setTime"] ~= nil then 
				  	t = math.min(1.0, (playdate.getCurrentTimeMilliseconds() - thisMatrixData[y][x]["setTime"])/gridSpaceAnimateTime)
			  	end 

				if thisImageIndex == imageIndex or puzzleComplete then 
			  		if thisMatrix[y][x] == 1 then
				   		gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
				   		gfx.fillRect(spacing*x, spacing*y, t*(spacing-1), t*(spacing-1))
			  		elseif thisMatrix[y][x] == -1 and not puzzleComplete then
				   		gfx.setDitherPattern(0.5,gfx.image.kDitherTypeDiagonalLine)
				   		gfx.fillRect(spacing*x + (1.0 - t)*spacing*0.5, spacing*y + (1.0 - t)*spacing*0.5, t*(spacing-1), t*(spacing-1))
					elseif thisMatrix[y][x] == 0 then 
					   gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
					   gfx.fillRect(spacing*x + t*spacing*0.5, spacing*y + t*spacing*0.5, (1.0 - t)*(spacing-1), (1.0 - t)*(spacing-1))
	
			  		end
				else 
		  			if thisMatrix[y][x] == 1 then
		   				gfx.setDitherPattern(0.5,gfx.image.kDitherTypeBayer8x8)
		   				gfx.fillRect(spacing*x, spacing*y, spacing-1, spacing-1)
					elseif thisMatrix[y][x] == -1 and not puzzleComplete then
		   				gfx.setDitherPattern(0.75,gfx.image.kDitherTypeDiagonalLine)
		   				gfx.fillRect(spacing*x, spacing*y, spacing-1, spacing-1)
					end	
				end 
		  	end
	 	end
		 
		gfx.unlockFocus()
	end 
	
	playerImage:draw(adjustedOffsetX, adjustedOffsetY)
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
	 local thisMatrixData = self.matricesData[imageIndex]

	 if not playdate.buttonIsPressed(playdate.kButtonRight)
		 and not playdate.buttonIsPressed(playdate.kButtonDown)
		 and not playdate.buttonIsPressed(playdate.kButtonLeft)
		 and not playdate.buttonIsPressed(playdate.kButtonUp)
		 then
		  lastDirPressed = 0
	 end

	 
	--  if playdate.buttonIsPressed(playdate.kButtonB) and playdate.buttonIsPressed(playdate.kButtonA) then 
	--  	 gfx.drawText(notePitch, 50, 50)
	-- 	  if playdate.buttonJustPressed(playdate.kButtonUp) then 
	-- 		  notePitch += 10
	-- 	 elseif playdate.buttonJustPressed(playdate.kButtonDown) then 
	-- 		 notePitch -= 10
	-- 	 end
	--  else 
	-- 
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
	-- end

	 notePitch = math.max(0, notePitch)

	 if (playdate.buttonIsPressed(playdate.kButtonA) or playdate.buttonIsPressed(playdate.kButtonB)) and newCellTarget then
	 	 local prevVal = thisMatrix[cursorLocY][cursorLocX]
 	     if prevVal ~= setVal then	 
 		 	thisMatrix[cursorLocY][cursorLocX] = setVal
			thisMatrixData[cursorLocY][cursorLocX]["setTime"] = playdate.getCurrentTimeMilliseconds()
			animateTillTimeStamp = playdate.getCurrentTimeMilliseconds() + gridSpaceAnimateTime + 100
		 	playerImages[imageIndex] = nil		 	
		 	notifyGridChanged()
	
		 	if setVal == 1 then
			  	synth:playNote(40, 5, 0.016)
		 	elseif setVal == -1 then
			  	noiseSynth:playNote(50, 0.15, 0.016)			  	
		 	elseif setVal == 0 then 
				noiseSynth:setDecay(0.05)		 	 	
				noiseSynth:playNote(10, 0.15, 0.016)
		 	end 
		end
	 end
end

function Grid:getZoomForSpacing(thisSpacing)
	local delta = thisSpacing - minSpacing

	if thisSpacing > maxSpacing then 
		return maxZoom
	elseif thisSpacing >= minSpacing then 
		return playdate.math.lerp(1.0, maxZoom, (thisSpacing-minSpacing)/maxSpacing)
	else 
		return playdate.math.lerp(0.0, 1.0, (thisSpacing-zoomOutMinSpacing)/minSpacing)
	end 
end

function Grid:calculateIdealSpacing() 
	local blockWidth = puzzle.pieceWidth
	local totalBlockWidth = math.ceil(blockWidth * 1.5)
	local blockHeight = puzzle.pieceHeight
	local totalBlockHeight = math.ceil(blockHeight * 1.5)
	local maxSpacingWidth = math.floor(screenWidth/totalBlockWidth)
	local maxSpacingHeight = math.floor(screenHeight/totalBlockHeight)
	
	return math.min(maxSpacingWidth, maxSpacingHeight)
end 

function Grid:checkCrank()
   
   local crankDelta = playdate.getCrankChange()   
   crankDelta /= 360.0
   
   local newZoom = zoom + crankDelta
   newZoom = math.max(0.0, math.min(newZoom, maxZoom))

  if zoom ~= newZoom then 
  	zoom = newZoom
    for i=0, #playerImages do 
		playerImages[i] = nil
	end 
  end 

  if zoom >= 1.0 then 
  	targetSpacing = playdate.math.lerp(minSpacing,maxSpacing,(zoom - 1.0)/(maxZoom - 1.0))	
  else
    targetSpacing = playdate.math.lerp(zoomOutMinSpacing, minSpacing, zoom)
  end 

  if #puzzle.imgmatrices == 1 then 
  	zoom = math.max(zoom, 1.0)
  end	 

  -- targetSpacing = math.ceil(targetSpacing)
  local blockWidth = puzzle.pieceWidth
  local paddingWidth = math.ceil(puzzle.pieceWidth * 0.5)
  if self:isOnRightHandSide() then 
  	targetOffsetX = (screenWidth - blockWidth*targetSpacing)*0.5
  else 
  	targetOffsetX = (screenWidth - blockWidth*targetSpacing)*0.5 + paddingWidth*fontSize*0.5
  end 
  local blockHeight = puzzle.pieceHeight
  local paddingHeight = math.ceil(puzzle.pieceHeight * 0.5)
  if self:isOnLowerSide() then 
	  targetOffsetY = (screenHeight - blockHeight*targetSpacing)*0.5
  else 
  	targetOffsetY = (screenHeight - blockHeight*targetSpacing)*0.5 + paddingHeight*fontSize*0.5
  end

  offsetX = targetOffsetX
  offsetY = targetOffsetY
  spacing = targetSpacing
  
   local row = math.floor((imageIndex-1) / puzzle.dimensionWidth)
   local column = math.floor((imageIndex-1) % puzzle.dimensionWidth)
  
   targetDrawOffsetX = math.floor(-1.0 * column * puzzle.pieceWidth*spacing) -- - column * paddingWidth*fontSize
   targetDrawOffsetY = math.floor(-1.0 * row * puzzle.pieceHeight*spacing)  -- - row * paddingHeight*fontSize
end

function updateDrawOffset()   
	local drawOffsetX, drawOffsetY = gfx.getDrawOffset()

	print(drawOffsetX..","..drawOffsetY)

	drawOffsetX = playdate.math.lerp(drawOffsetX, targetDrawOffsetX, 0.5)
	drawOffsetY = playdate.math.lerp(drawOffsetY, targetDrawOffsetY, 0.5)
	
   -- gfx.setDrawOffset(drawOffsetX,drawOffsetY)
    gfx.setDrawOffset(targetDrawOffsetX, targetDrawOffsetY)
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
	  for i=0, #headerRowImages do 
	  	headerRowImages[i] = nil
	  end 

	  for i=0, #headerColumnImages do 
	 		headerColumnImages[i] = nil
	   end 

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
		updateDrawOffset()
	
 		for i = 1, #self.matrices do 
			self:drawPlayerImage(i)
 		end

		 for i = 1, #self.matrices do 
			 self:drawGrid(i)
		 end

		 puzzle.headersNeedRedisplay = false

 		if zoom >= 1.0 then
			self:updateCursor()
			self:drawCursor()
 		else
			self:updateBoardCursor()
			self:drawBoardCursor()
 		end

	end
end



