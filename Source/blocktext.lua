import "CoreLibs/graphics"

local gfx = playdate.graphics

function drawBlockText(text,posx,posy,pixelsize)	
	for i = 1, #text do
		local c = text:sub(i,i)
		local img = nil 
		if c == ' ' then 
			img = gfx.image.new('assets/letters/space.png')  
		else 
			img = gfx.image.new('assets/letters/'..c .. '.png')  
		end
		
		for y= 0, img.height-1
		do
			for x= 0, img.width-1
			do
				sample = img:sample(x,y)
				if sample == gfx.kColorBlack then
					gfx.fillRect(posx + (i-1) * 1.1 * img.width * pixelsize + pixelsize*x, posy + pixelsize*y, pixelsize-1, pixelsize-1)
				end 
			end
		end
	end	
end 
