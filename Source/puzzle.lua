import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx = playdate.graphics
local files = playdate.file.listFiles('assets/puzzles/')

class('Puzzle').extends()

local function getPuzzleData()
	return levelData 		
end 

function Puzzle:init(puzzleData)
	Puzzle.super.init(self)
	self.rowData = nil 
	self.colData = nil 
	
	self:loadPuzzle(puzzleData)
end

function Puzzle:loadPuzzle(puzzleData)
   local img =  gfx.image.new('assets/puzzles/images/' .. puzzleData['image'])  
   
   self.rowData = table.create(img.height,0)
   -- get row data
   for y= 0, img.height-1
   do
	   local rowIndex = y+1
	   local rowCount = 0
	   self.rowData[rowIndex] = table.create(img.width,0)
	   for x= 0, img.width-1
	   do
		   local sample = img:sample(x,y)
		   
		   if sample == gfx.kColorBlack then
			   rowCount+= 1  
		   else
			   if rowCount > 0 then 
				   table.insert(self.rowData[rowIndex],rowCount)
				   rowCount = 0    
			   end 
		   end
	   end
   
	   if rowCount > 0 then 
		   table.insert(self.rowData[rowIndex],rowCount)
		   rowCount = 0    
	   end 
	   
	   if #self.rowData[rowIndex] == 0 then 
		   table.insert(self.rowData[rowIndex],0)
	   end 
   end
   
   self.colData = table.create(img.width,0)

   -- get column data
   for x= 0, img.width-1
   do
	   local colIndex = x+1
	   local colCount = 0
	   self.colData[colIndex] = table.create(img.height,0)
	   for y= 0, img.height-1
	   do
		   local sample = img:sample(x,y)
		   
		   if sample == gfx.kColorBlack then
			   colCount+= 1  
		   else
			   if colCount > 0 then 
				   table.insert(self.colData[colIndex],colCount)
				   colCount = 0    
			   end 
		   end
	   end
   
	   if colCount > 0 then 
		   table.insert(self.colData[colIndex],colCount)
		   colCount = 0    
	   end 
	   
	   
	   if #self.colData[colIndex] == 0 then 
		   table.insert(self.colData[colIndex],0)
	   end 
   end
end

function Puzzle:drawImage(posx, posy, pixelsize) 
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
   local img = gfx.image.new('assets/puzzles/'..files[fileIndex])  

	for y= 0, img.height-1
	do
		for x= 0, img.width-1
		do
			sample = img:sample(x,y)
			if sample == gfx.kColorBlack then
				gfx.fillRect(posX + pixelsize*x, posY + pixelsize*y, pixelsize-1, pixelsize-1)
			end 
		end
	end
end