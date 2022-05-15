import "CoreLibs/graphics"
import "CoreLibs/math"
import "CoreLibs/object"
import 'puzzle'
import 'save_funcs'
import 'funcs'

local gfx = playdate.graphics

class('Game').extends()

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
local kDefaultOffsetX <const> = 128
local kDefaultOffsetY <const> = 72

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
local puzzleComplete = false
local puzzleFinishTimestamp = 0.0

local initialized = false
local gridFont <const> = gfx.font.new('assets/Picross-Small')
gridFont:setTracking(0)
gridFont:setLeading(4)

local gridFontNoKearning <const> = gfx.font.new('assets/Picross-Small-no-kearning')
gridFontNoKearning:setTracking(2)

local blockyFont <const> = gfx.font.new('assets/blocky')
blockyFont:setTracking(1)


function Game:init()
    Game.super.init(self)
end

function Game:loadPuzzle(puzzleSelected)
    puzzleComplete = false
    initialized = false
    puzzle = puzzleSelected

    matrix = table.create(puzzle.pieceHeight)
    for y = 0, puzzle.pieceHeight-1 do
        matrix[y] = table.create(puzzle.pieceWidth, 0)
        for x = 0, puzzle.pieceWidth-1 do
            matrix[y][x] = 0
        end
    end

    imgmatrix = puzzle.imgmatrices[imageIndex]

    -- load font

   gfx.setFont(gridFont)

   puzzleFinishTimestamp = 0.0
   offsetX = kDefaultOffsetX
   offsetY = kDefaultOffsetY
   spacing = kDefaultSpacing
   
   initTimestamp = playdate.getCurrentTimeMilliseconds()
   initialized = true
end

function Game:drawGrid()
    gfx.setFont(gridFont)

    gfx.drawLine(offsetX, offsetY, offsetX + #puzzle.colData[imageIndex] * spacing, offsetY)
    -- draw row data
    local rowNum = 0
    for key,value in pairs(puzzle.rowData[imageIndex]) do
        local drawStr = ""
        for key2,value2 in pairs(value) do
            drawStr = drawStr .. " " .. value2
        end
       if rowNum >= 1 then
          if rowNum % 5 == 0 or zoom < 1.0 then
           gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
          else
           gfx.setDitherPattern(0.5,gfx.image.kDitherTypeVerticalLine)
          end
          gfx.drawLine(offsetX, offsetY + rowNum * spacing - 1, offsetX + #puzzle.colData[imageIndex] * spacing, offsetY + rowNum * spacing - 1)
       end

       if zoom >= 1.0 then
           if cursorLocY == rowNum then
              gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
              gfx.setColor(gfx.kColorBlack)
              gfx.fillRect(0, offsetY + rowNum * spacing - 2, offsetX, spacing)
              gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)

              gfx.drawTextAligned(drawStr, offsetX - 4, offsetY + rowNum * spacing, kTextAlignment.right)
              gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
                  else
                  gfx.drawTextAligned(drawStr, offsetX - 4, offsetY + rowNum * spacing, kTextAlignment.right)
            end
           end

       rowNum += 1
    end

    gfx.drawLine(offsetX, offsetY, offsetX, offsetY + #puzzle.rowData[imageIndex] * spacing)
    -- draw col data
    local colNum = 0
    local maxColVals = 6
    for key,value in pairs(puzzle.colData[imageIndex]) do
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
              if colNum % 5 == 0 or zoom < 1.0 then
                 gfx.setDitherPattern(0.0,gfx.image.kDitherTypeHorizontalLine)
              else
                gfx.setDitherPattern(0.5,gfx.image.kDitherTypeHorizontalLine)
              end

               gfx.drawLine(offsetX + colNum * spacing - 1, offsetY, offsetX + colNum * spacing - 1, offsetY  + #puzzle.rowData[imageIndex] * spacing)
        end

		if zoom >= 1.0 then

        	if cursorLocX == colNum then
            	gfx.setDitherPattern(0.0, gfx.image.kDitherTypeVerticalLine)
            	gfx.setColor(gfx.kColorBlack)
            	gfx.fillRect(offsetX + colNum * spacing, 0, spacing, offsetY)
            	gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
             	gfx.drawTextAligned(drawStr, offsetX + colNum * spacing + 2, 10 + offsetY - spacing*maxColVals, kTextAlignment.centered)
            	gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
	
         	else
             	gfx.drawTextAligned(drawStr, offsetX + colNum * spacing + 2, 10 + offsetY - spacing*maxColVals, kTextAlignment.centered)
    
         	end
		end


       colNum += 1
    end
end

function Game:drawPlayerImage()
    local won = true

    for y= 0, #matrix
    do
        for x= 0, #matrix[y]
        do
            if imgmatrix[y][x] == 1 and matrix[y][x] ~= 1
                or imgmatrix[y][x] == 0 and matrix[y][x] == 1 then
                won = false
            end

            if matrix[y][x] == 1 then
                gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
                gfx.fillRect(offsetX + spacing*x, offsetY + spacing*y, spacing-1, spacing-1)
            elseif matrix[y][x] == -1 and not puzzleComplete then
                gfx.setDitherPattern(0.5,gfx.image.kDitherTypeDiagonalLine)
                gfx.fillRect(offsetX + spacing*x, offsetY + spacing*y, spacing-1, spacing-1)
            end
        end
    end

    gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)

    if won and not puzzleComplete then
        Game:win()
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
       if setVal == 1 then

              synth:playNote(60+setContinue*20, 1, 0.033)
           setContinue += 1
       elseif setVal == -1 then
            noiseSynth:playNote(60, 0.5, 0.016)
       end
    end
end

function Game:win()
    local puzzleId = puzzleData['id']
    local clearTime = playdate.getCurrentTimeMilliseconds() - initTimestamp
    savePuzzleClear(puzzleId, clearTime)
    puzzleFinishTimestamp = playdate.getCurrentTimeMilliseconds()
    puzzleComplete = true
end

function Game:drawTime()
    gfx.setFont(gridFontNoKearning)

    gfx.drawTextAligned(timeToString(playdate.getCurrentTimeMilliseconds() - initTimestamp), 100, 20, kTextAlignment.right)
end

function Game:drawPuzzleComplete()
    gfx.setFont(blockyFont)
    gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
    gfx.drawTextAligned("COMPLETED IN " .. getClearTimeString(puzzleData['id']), 200, screenHeight - (screenHeight-spacing*#puzzle.rowData[imageIndex])/2.0 + 20, kTextAlignment.center)
end

function Game:debugCompletePuzzle()
    for y= 0, #imgmatrix
    do
        for x= 0, #imgmatrix[y]
        do
            matrix[y][x] = imgmatrix[y][x]

        end
    end
end

function Game:checkCrank()
    local crankPos = playdate.getCrankPosition()
    if crankPos > 240.0 then
        crankPos = 0.0
    end

    crankPos = math.max(0.0,math.min(crankPos,180.0))


    zoom = 1.0 - crankPos/180.0

    offsetX = playdate.math.lerp(kDefaultOffsetX, kZoomOutOffsetX, 1.0 - zoom)
    offsetY = playdate.math.lerp(kDefaultOffsetY, kZoomOutOffsetY, 1.0 - zoom)
    spacing = math.ceil(playdate.math.lerp(kDefaultSpacing, kZoomOutSpacing, 1.0 -zoom))
end

function Game:update()
    if initialized and playdate.getCurrentTimeMilliseconds() - initTimestamp > 100 then
        gfx.clear()

        if not puzzleComplete then
            self:checkCrank()
            self:drawGrid()
            
			if zoom >= 1.0 then 
				self:updateCursor()
            	self:drawCursor()
			end
            self:drawTime()
        end

        if puzzleComplete then
            offsetX = playdate.math.lerp(offsetX, (screenWidth - spacing*#puzzle.colData[imageIndex])/2.0, math.min(1.0,(playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp)/1000.0))
            offsetY = playdate.math.lerp(offsetY,  (screenHeight - spacing*#puzzle.rowData[imageIndex])/2.0, math.min(1.0, (playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp)/1000.0))

            self:drawPuzzleComplete()
            if playdate.buttonJustPressed(playdate.kButtonA) and playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp > 100 then
                goLevelSelect()
            end
        end

        self:drawPlayerImage()
    end
end



