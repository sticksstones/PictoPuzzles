function tabledeepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[tabledeepcopy(orig_key)] = tabledeepcopy(orig_value)
		end
		setmetatable(copy, tabledeepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function timeToString(milliseconds)
	totalSeconds = milliseconds/1000
	clearMilliseconds = math.floor(milliseconds%1000)
	clearMinutes = math.floor(totalSeconds/60)
	clearSeconds = math.floor(totalSeconds%60)
	return string.format("%02d:%02d:%03d",clearMinutes,clearSeconds,clearMilliseconds)	
end 