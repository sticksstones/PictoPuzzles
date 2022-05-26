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
gfx.setColor(gfx.kColorBlack)

class('Game').extends()

local grid = Grid()
local puzzle = nil
local puzzleComplete = false
local puzzleFinishTimestamp = 0.0

local initialized = false

function Game:init()
 	Game.super.init(self)
end

function Game:loadPuzzle(puzzleSelected)
  grid:loadPuzzle(puzzleSelected)
 	puzzleComplete = false
 	initialized = false
 	puzzle = puzzleSelected

	puzzleFinishTimestamp = 0.0
	initTimestamp = playdate.getCurrentTimeMilliseconds()
	initialized = true
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

         if playdate.buttonJustPressed(playdate.kButtonA) and playdate.getCurrentTimeMilliseconds() - puzzleFinishTimestamp > 100 then
            goLevelSelect()
         end
      end
 	end
end



