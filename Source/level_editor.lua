import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/ui"
import "CoreLibs/keyboard"
import 'blocktext'
import 'puzzle'
import 'grid'

local gfx = playdate.graphics

local active = false

class('LevelEditor').extends()

function LevelEditor:init() 
	LevelEditor.super.init(self)
end

function LevelEditor:start() 
	active = true

	self.puzzleData = {}
	self.puzzleData['name'] = "creation"
	self.puzzleData['images'] = {}
	for i=1, 4 do 
		local canvas = playdate.graphics.image.new(25, 15, gfx.kColorWhite)
		local filename = self.puzzleData['name']..i
		playdate.datastore.writeImage(canvas, 'assets/puzzles/images/' .. filename)
		table.insert(self.puzzleData['images'],filename)
	end 
	
	grid = Grid()
	self.puzzle = Puzzle(self.puzzleData)
	grid:loadPuzzle(self.puzzle)
end 

function LevelEditor:update() 
	gfx.clear()
	-- playdate.keyboard.show()
	grid:update()
	
	if playdate.buttonJustPressed(playdate.kButtonB) then 
		active = false
		-- playdate.keyboard.hide()
		goMainMenu()
	end 
end 

function LevelEditor:savePuzzle()	
	self.puzzle:writeMatricesToImages(self.puzzleData['images'])
end

function LevelEditor:gridChanged() 
	self.puzzle:mirrorMatrixToImage(grid.matrices)
end 

