local E, L, DF = unpack(select(2, ...)); --Engine
local DT = E:GetModule('DataTexts')

-- initial delay for update (let the ui load)
local int, int2 = 6, 5
local statusColors = {
	"|cff0CD809",
	"|cffE8DA0F",
	"|cffFF9000",
	"|cffD80909"
}

local bandwidthString = "%.2f Mbps"
local percentageString = "%.2f%%"
local homeLatencyString = "%d ms"
local kiloByteString = "%d kb"
local megaByteString = "%.2f mb"

local function formatMem(memory)
	local mult = 10^1
	if memory > 999 then
		local mem = ((memory/1024) * mult) / mult
		return string.format(megaByteString, mem)
	else
		local mem = (memory * mult) / mult
		return string.format(kiloByteString, mem)
	end
end

local memoryTable = {}
local function RebuildAddonList()
	local addOnCount = GetNumAddOns()
	if (addOnCount == #memoryTable) then return end

	-- Number of loaded addons changed, create new memoryTable for all addons
	memoryTable = {}
	for i = 1, addOnCount do
		memoryTable[i] = { i, select(2, GetAddOnInfo(i)), 0, IsAddOnLoaded(i) }
	end
end

local function UpdateMemory()
	-- Update the memory usages of the addons
	UpdateAddOnMemoryUsage()
	-- Load memory usage in table
	local addOnMem = 0
	local totalMemory = 0
	for i = 1, #memoryTable do
		addOnMem = GetAddOnMemoryUsage(memoryTable[i][1])
		memoryTable[i][3] = addOnMem
		totalMemory = totalMemory + addOnMem
	end
	-- Sort the table to put the largest addon on top
	table.sort(memoryTable, function(a, b)
		if a and b then
			return a[3] > b[3]
		end
	end)
	
	return totalMemory
end

local function Update(self, t)
	int = int - t
	int2 = int2 - t
	
	if int < 0 then
		RebuildAddonList()
		int = 10
	end
	if int2 < 0 then
		local framerate = floor(GetFramerate())
		local fpscolor = 4
		local latency = select(4, GetNetStats()) 
		local latencycolor = 4
					
		if latency < 150 then
			latencycolor = 1
		elseif latency >= 150 and latency < 300 then
			latencycolor = 2
		elseif latency >= 300 and latency < 500 then
			latencycolor = 3
		end
		if framerate >= 30 then
			fpscolor = 1
		elseif framerate >= 20 and framerate < 30 then
			fpscolor = 2
		elseif framerate >= 10 and framerate < 20 then
			fpscolor = 3
		end
		local displayFormat = string.join("", "FPS: ", statusColors[fpscolor], "%d|r MS: ", statusColors[latencycolor], "%d|r")
		self.text:SetFormattedText(displayFormat, framerate, latency)
		int2 = 1
	end
end

local function Click()
	collectgarbage("collect");
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	local bandwidth = GetAvailableBandwidth()
	local home_latency = select(3, GetNetStats()) 
	
	GameTooltip:AddDoubleLine(L['Home Latency:'], string.format(homeLatencyString, home_latency), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
	
	if bandwidth ~= 0 then
		GameTooltip:AddDoubleLine(L['Bandwidth'] , string.format(bandwidthString, bandwidth),0.69, 0.31, 0.31,0.84, 0.75, 0.65)
		GameTooltip:AddDoubleLine(L['Download'] , string.format(percentageString, GetDownloadedPercentage() *100),0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
		GameTooltip:AddLine(" ")
	end
	
	local totalMemory = UpdateMemory()
	GameTooltip:AddDoubleLine(L['Total Memory:'], formatMem(totalMemory), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
	GameTooltip:AddLine(" ")
	for i = 1, #memoryTable do
		if (memoryTable[i][4]) then
			local red = memoryTable[i][3] / totalMemory
			local green = 1 - red
			GameTooltip:AddDoubleLine(memoryTable[i][2], formatMem(memoryTable[i][3]), 1, 1, 1, red, green + .5, 0)
		end						
	end
	GameTooltip:Show()
end

--[[
	DT:RegisterDatatext(name, events, eventFunc, updateFunc, clickFunc, onEnterFunc)
	
	name - name of the datatext (required)
	events - must be a table with string values of event names to register 
	eventFunc - function that gets fired when an event gets triggered
	updateFunc - onUpdate script target function
	click - function to fire when clicking the datatext
	onEnterFunc - function to fire OnEnter
]]
DT:RegisterDatatext('System', nil, nil, Update, Click, OnEnter)

