import "CoreLibs/graphics"

local gfx = playdate.graphics

function getBlockTextImage(text,pixelsize)
	local img = gfx.image.new(pixelsize*#text*1.1*5,5*pixelsize*#text)
	gfx.lockFocus(img)
	gfx.setColor(gfx.kColorBlack)
	for i = 1, #text do
		local c = text:sub(i,i)
		local img = nil 
		if c == ' ' then 
			img = gfx.image.new('assets/letters/space.png')  
		elseif c == '?' then 
			img = gfx.image.new('assets/letters/question.png')  
		else  
			img = gfx.image.new('assets/letters/'.. c .. '.png')  
		end
		
		for y= 0, img.height-1
		do
			for x= 0, img.width-1
			do
				sample = img:sample(x,y)
				if sample == gfx.kColorBlack then
					gfx.fillRect((i-1) * 1.1 * img.width * pixelsize + pixelsize*x, pixelsize*y, pixelsize-1, pixelsize-1)
				end 
			end
		end
	end

	gfx.unlockFocus()
	return img		
end 

function drawBlockText(text,posx,posy,pixelsize,borderWidth,selected)
	borderWidth = borderWidth or 0
	selected = selected or true
	for i = 1, #text do
		local c = text:sub(i,i)
		local img = nil 
		if c == ' ' then 
			img = gfx.image.new('assets/letters/space.png')  
		elseif c == '?' then 
			img = gfx.image.new('assets/letters/question.png')  
		else  
			img = gfx.image.new('assets/letters/'.. c .. '.png')  
		end
		
		for y= 0, img.height-1
		do
			for x= 0, img.width-1
			do
				sample = img:sample(x,y)
				if sample == gfx.kColorBlack then
					-- if selected and backdrop then 
					-- 	gfx.setColor(gfx.kColorWhite)
					-- else 
					-- 	gfx.setColor(gfx.kColorBlack)
					-- end 
					
					if borderWidth == 0 then 
						gfx.fillRect(posx + (i-1) * 1.1 * img.width * pixelsize + pixelsize*x, posy + pixelsize*y, pixelsize-1, pixelsize-1)
					end 
				elseif borderWidth > 0 then 
						gfx.setColor(gfx.kColorBlack)
						gfx.fillRect(posx + (i-1) * 1.1 * img.width * pixelsize + pixelsize*x, posy + pixelsize*y, pixelsize-1, pixelsize-1)
					
				end 
			end
		end
	end	
end 
