savedata = nil

function loadSave() 
	if playdate.datastore.read() == nil then 
	   savedata = {} 
	   savedata['puzzles'] = {}
	   playdate.datastore.write(savedata)
	else 
	   savedata = playdate.datastore.read()   
	end 
end 

function savePuzzleClear(puzzleId, clearTime) 
	if savedata['puzzles'][puzzleId] == nil then 
		savedata['puzzles'][puzzleId] = {} 		
	end 
		
	savedata['puzzles'][puzzleId]['clearTime'] = clearTime
	savedata['puzzles'][puzzleId]['clearDate'] = playdate.epochFromGMTTime(playdate.getGMTTime())
	
	writeSave()
end 

function isPuzzleCleared(puzzleId)
	return savedata['puzzles'][puzzleId] ~= nil
end 

function getClearTimeString(puzzleId)
	if isPuzzleCleared(puzzleId) then 
		local clearTime = savedata['puzzles'][puzzleId]['clearTime']
		return timeToString(clearTime)
	else 
		return ""
	end 
end

function writeSave() 
	playdate.datastore.write(savedata)	
end 