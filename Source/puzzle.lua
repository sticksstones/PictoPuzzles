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
	self.imgmatrices = nil
	self:loadPuzzle(self.puzzleData)
end

function Puzzle:loadImage(img)
  local imgmatrix = table.create(img.height,0)  
  
   -- get row data
   for y= 0, img.height-1 do
	   imgmatrix[y] = table.create(img.width,0)
	   for x= 0, img.width-1 do		
		   local sample = img:sample(x,y)
		   if sample == gfx.kColorBlack then
			   imgmatrix[y][x] = 1
		   else
			   imgmatrix[y][x] = 0
		   end
	   end
	end 
   
   self.pieceWidth = #imgmatrix[1]+1
   self.pieceHeight = #imgmatrix+1
   table.insert(self.imgmatrices, imgmatrix)
end 

function Puzzle:generateHeaders()
	count = #self.colData
	for i=0, count do self.colData[i]=nil end
	count = #self.rowData
	for i=0, count do self.rowData[i]=nil end

  for i = 1, #self.imgmatrices do 
  	local imgmatrix = self.imgmatrices[i]  
  	local width = #imgmatrix[1]
  	local height = #imgmatrix

  	local thisRowData = table.create(height,0)  
   	-- get row data
   	for y= 0, height
   	do
	   	local rowIndex = y+1
	   	local rowCount = 0
	   	thisRowData[rowIndex] = table.create(width,0)
	   	for x= 0, width do		   	
		   	if imgmatrix[y][x] == 1 then
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
   	
   	local thisColData = table.create(width,0)
	
   	-- get column data
   	for x= 0, width
   	do
	   	local colIndex = x+1
	   	local colCount = 0
	   	thisColData[colIndex] = table.create(height,0)
	   	for y= 0, height
	   	do		  		   
		   	if imgmatrix[y][x] == 1 then
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
   	
   	table.insert(self.rowData, thisRowData)
   	table.insert(self.colData, thisColData)
  end
end 

function Puzzle:loadPuzzle(puzzleData)
	self.imgmatrices = table.create(#self.puzzleData['images'],0)
	
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

	for i=1, #self.imgmatrices do 
		local imgmatrix = self.imgmatrices[i]
		local row = math.floor((i-1) / self.dimensionWidth)
		local column = math.floor((i-1) % self.dimensionWidth)

		for y=0, #imgmatrix do 
			for x=0, #imgmatrix[y] do
				if imgmatrix[y][x] == 1 then 
					gfx.fillRect(
						posx + (column * (#imgmatrix[y]+1)*pixelsize) + pixelsize*x, 
						posy + (row * (#imgmatrix+1)*pixelsize) + pixelsize*y, 
						pixelsize-1, pixelsize-1
					)					
				end 	
			end 
		end 		
	end 
end

function Puzzle:mirrorMatrixToImage(matrices)
	for i=1, #matrices do 
		local matrix = matrices[i]
		local imgmatrix = self.imgmatrices[i]
		for y = 0, #matrix do 
			for x = 0, #matrix[y] do 
				imgmatrix[y][x] = matrix[y][x]
			end 
		end 
	end 
	
	self:generateHeaders()
end

function Puzzle:writeMatricesToImages()
	
	for i=1, #self.imgmatrices do 
		local imgmatrix = self.imgmatrices[i]
		local img = gfx.image.new('assets/puzzles/images/' .. self.puzzleData['images'][i])
		gfx.lockFocus(img)
		for y=0, #imgmatrix do 
			for x=0, #imgmatrix[y] do 
				if imgmatrix[y][x] == 1 then 
					gfx.setColor(gfx.kColorBlack)
				else
			   		gfx.setColor(gfx.kColorWhite) 
				end 
				gfx.fillRect(x,y,1,1)
			end
		end 
		gfx.unlockFocus()
		playdate.datastore.writeImage(img, 'assets/puzzles/images/' .. self.puzzleData['images'][i])
	end 
end