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
	self.rowData = {} 
	self.colData = {} 
	self.totalHeight = 0
	self.totalWidth = 0
	self.pieceHeight = 0
	self.pieceWidth = 0
	self.puzzleData = puzzleData
	self:loadPuzzle(self.puzzleData)
end

function Puzzle:loadImage(img)
  
  local thisRowData = table.create(img.height,0)
   -- get row data
   for y= 0, img.height-1
   do
	   local rowIndex = y+1
	   local rowCount = 0
	   thisRowData[rowIndex] = table.create(img.width,0)
	   for x= 0, img.width-1
	   do
		   local sample = img:sample(x,y)
		   
		   if sample == gfx.kColorBlack then
			   rowCount+= 1  
		   else
			   if rowCount > 0 then 
				   table.insert(thisRowData[rowIndex],rowCount)
				   rowCount = 0    
			   end 
		   end
	   end
   
	   if rowCount > 0 then 
		   table.insert(thisRowData[rowIndex],rowCount)
		   rowCount = 0    
	   end 
	   
	   if #thisRowData[rowIndex] == 0 then 
		   table.insert(thisRowData[rowIndex],0)
	   end 
   end
   
   local thisColData = table.create(img.width,0)

   -- get column data
   for x= 0, img.width-1
   do
	   local colIndex = x+1
	   local colCount = 0
	   thisColData[colIndex] = table.create(img.height,0)
	   for y= 0, img.height-1
	   do
		   local sample = img:sample(x,y)
		   
		   if sample == gfx.kColorBlack then
			   colCount+= 1  
		   else
			   if colCount > 0 then 
				   table.insert(thisColData[colIndex],colCount)
				   colCount = 0    
			   end 
		   end
	   end
   
	   if colCount > 0 then 
		   table.insert(thisColData[colIndex],colCount)
		   colCount = 0    
	   end 
	   
	   
	   if #thisColData[colIndex] == 0 then 
		   table.insert(thisColData[colIndex],0)
	   end 
   end
   
   self.pieceWidth = #thisColData
   self.pieceHeight = #thisRowData
   table.insert(self.rowData, thisRowData)
   table.insert(self.colData, thisColData)
end 

function Puzzle:loadPuzzle(puzzleData)
	for i=1, #self.puzzleData['images'] do 
		local img = gfx.image.new('assets/puzzles/images/' .. self.puzzleData['images'][i])  
		self:loadImage(img)
	end 
	
	self.dimensionWidth = self.puzzleData['override-width'] ~= nil and self.puzzleData['override-width'] or math.sqrt(#self.puzzleData['images'])
	self.dimensionHeight = self.puzzleData['override-height'] ~= nil and self.puzzleData['override-height'] or math.sqrt(#self.puzzleData['images'])
	self.totalWidth = math.floor(self.dimensionWidth * self.pieceWidth)
	self.totalHeight = math.floor(self.dimensionHeight * self.pieceHeight)

end

function Puzzle:getPixelSizeForWidth(width)
	local constrainedDimension = self.totalHeight / self.totalWidth > 1.0 and self.totalHeight or self.totalWidth 
	return math.min(math.max(2, math.floor(width / constrainedDimension)),8)
end 

function Puzzle:drawImage(posx, posy, width) 
	gfx.setDitherPattern(0.0,gfx.image.kDitherTypeVerticalLine)
	
	local pixelsize = self:getPixelSizeForWidth(width)

	for i=1, #self.puzzleData['images'] do 
		local img = gfx.image.new('assets/puzzles/images/' .. self.puzzleData['images'][i]) 		
		local row = math.floor((i-1) / self.dimensionWidth)
		local column = math.floor((i-1) % self.dimensionWidth)

		for y= 0, img.height-1
		do
			for x= 0, img.width-1
			do
				local sample = img:sample(x,y)
				if sample == gfx.kColorBlack then												
					gfx.fillRect(
						posx + (column * img.width*pixelsize) + pixelsize*x, 
						posy + (row * img.height*pixelsize) + pixelsize*y, 
						pixelsize-1, pixelsize-1
					)
				end 
			end
		end
	end
end