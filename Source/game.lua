import "CoreLibs/graphics"
import "CoreLibs/math"
import "CoreLibs/object"
import "CoreLibs/easing"
import "CoreLibs/animator"
import 'puzzle'
import 'save_funcs'
import 'grid'
import 'funcs'

local gfx = playdate.graphics

class('Game').extends()

gfx.setColor(gfx.kColorBlack)

local grid = Grid()

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()

local puzzle = nil
local matricesCompletionStatus = nil

local puzzleComplete = false
local puzzleFinishTimestamp = 0.0
local completedTextHeight = 220.0

local initialized = false

function Game:init()
 	Game.super.init(self)
end

function Game:loadPuzzle(puzzleSelected)
  grid:loadPuzzle(puzzleSelected)
 	puzzleComplete = false
 	initialized = false
 	puzzle = puzzleSelected

  matricesCompletionStatus = table.create(#grid.matrices,0)

 	for i=1, #puzzle.imgmatrices do
      matricesCompletionStatus[i] = 0
 	end

	puzzleFinishTimestamp = 0.0
	initTimestamp = playdate.getCurrentTimeMilliseconds()
	initialized = true
end

-- function Game:drawPlayerImage(overrideImageIndex)
-- 	local thisImageIndex = overrideImageIndex and overrideImageIndex or imageIndex
-- 	local thisMatrix = matrices[thisImageIndex]
-- 	local thisImgMatrix = puzzle.imgmatrices[thisImageIndex]
--    local row = math.floor((thisImageIndex-1) / puzzle.dimensionWidth)
--    local column = math.floor((thisImageIndex-1) % puzzle.dimensionWidth)
--    local adjustedOffsetX = offsetX + (column * (puzzle.pieceWidth*spacing))
--    local adjustedOffsetY = offsetY + (row * (puzzle.pieceHeight*spacing))
-- 
-- 	local matrixCompleted = true
-- 
--  	for y= 0, #thisMatrix
--  	do
--   		for x= 0, #thisMatrix[y]
--   		do
-- 				if thisImgMatrix[y][x] == 1 and thisMatrix[y][x] ~= 1
--  					or thisImgMatrix[y][x] == 0 and thisMatrix[y][x] == 1 then
--  					matrixCompleted = false
-- 				end
-- 
--         if thisImageIndex == imageIndex or puzzleComplete then 
-- 				  if thisMatrix[y][x] == 1 then
--  					  gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
--  					  gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
-- 				  elseif thisMatrix[y][x] == -1 and not puzzleComplete then
--  					  gfx.setDitherPattern(0.5,gfx.image.kDitherTypeDiagonalLine)
--  					  gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
-- 				  end
--         else 
--           if thisMatrix[y][x] == 1 then
--            gfx.setDitherPattern(0.5,gfx.image.kDitherTypeBayer8x8)
--            gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
--         elseif thisMatrix[y][x] == -1 and not puzzleComplete then
--            -- gfx.setDitherPattern(0.75,gfx.image.kDitherTypeBayer2x2)
--            gfx.setDitherPattern(0.75,gfx.image.kDitherTypeDiagonalLine)
--            gfx.fillRect(adjustedOffsetX + spacing*x, adjustedOffsetY + spacing*y, spacing-1, spacing-1)
--         end
-- 
--         end 
--   		end
--  	end
-- 
--  	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeDiagonalLine)
-- 
--    if matrixCompleted then 
--       matricesCompletionStatus[thisImageIndex] = 1
--    else 
--       matricesCompletionStatus[thisImageIndex] = 0
--    end
-- 
--    -- check win condition
--    local won = true
--    for i=1, #matricesCompletionStatus do 
--       if matricesCompletionStatus[i] == 0 then 
--          won = false
--       end
--    end 
-- 
--  	if won and not puzzleComplete then
--   		Game:win()
--  	end
-- end


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
 	gfx.drawTextAligned("COMPLETED IN " .. getClearTimeString(puzzleData['id']), 0.5*screenWidth, screenHeight - (screenHeight-spacing*puzzle.totalHeight)/2.0, kTextAlignment.center)
end

function Game:debugCompletePuzzle()
  for i = 1, #puzzle.imgmatrices do
    local thisMatrix = grid.matrices[i]
    local thisImgMatrix = puzzle.imgmatrices[i]
     for y = 0, #thisImgMatrix do
        for x = 0, #thisImgMatrix[y] do
           thisMatrix[y][x] = thisImgMatrix[y][x]
        end
     end
  end

  self:checkWin()
end

function Game:checkWin()
  local won = true
  for i = 1, #puzzle.imgmatrices do
    local thisMatrix = grid.matrices[i]
    local thisImgMatrix = puzzle.imgmatrices[i]
     for y = 0, #thisImgMatrix do
        for x = 0, #thisImgMatrix[y] do
          local matrixVal = thisMatrix[y][x]
          local imgMatrixVal = thisImgMatrix[y][x]
          if  imgMatrixVal == 1 and matrixVal ~= 1 or  
              imgMatrixVal == 0 and matrixVal == 1 then
              won = false
              return
           end
        end
     end
  end
  
  if won then 
    self:win()
  end
end

function Game:update()
   if initialized and playdate.getCurrentTimeMilliseconds() - initTimestamp > 100 then
      gfx.clear()

      if not puzzleComplete then
        grid:update()
        self:drawTime()
      else -- puzzle complete
         grid:updatePuzzleComplete()
         -- self:drawPuzzleComplete()

         if playdate.buttonJustPressed(playdate.kButtonA) and playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp > 100 then
            goLevelSelect()
         end
      end
 	end
end



