local E, L, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, ProfileDB, GlobalDB
local DT = E:GetModule('DataTexts')

local displayString = '';
local lastPanel

local function OnEvent(self, event, ...)
	lastPanel = self
	local free, total,used = 0, 0, 0
	for i = 0, NUM_BAG_SLOTS do
		free, total = free + GetContainerNumFreeSlots(i), total + GetContainerNumSlots(i)
	end
	used = total - free
	self.text:SetFormattedText(displayString, L["Bags"]..': ', used, total)
end

local function OnClick()
	ToggleAllBags()
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	for i = 1, MAX_WATCHED_TOKENS do
		local name, count, extraCurrencyType, icon, itemID = GetBackpackCurrencyInfo(i)
		if name and i == 1 then
			GameTooltip:AddLine(CURRENCY)
			GameTooltip:AddLine(" ")
		end
		if name and count then GameTooltip:AddDoubleLine(name, count, 1, 1, 1) end
	end	
	
	GameTooltip:Show()
end

local function ValueColorUpdate(hex, r, g, b)
	displayString = string.join("", "%s", hex, "%d/%d|r")

	if lastPanel ~= nil then
		OnEvent(lastPanel)
	end
end
E['valueColorUpdateFuncs'][ValueColorUpdate] = true

--[[
	DT:RegisterDatatext(name, events, eventFunc, updateFunc, clickFunc, onEnterFunc)

	name - name of the datatext (required)
	events - must be a table with string values of event names to register
	eventFunc - function that gets fired when an event gets triggered
	updateFunc - onUpdate script target function
	click - function to fire when clicking the datatext
	onEnterFunc - function to fire OnEnter
]]
DT:RegisterDatatext('Bags', {"PLAYER_ENTERING_WORLD", "BAG_UPDATE"}, OnEvent, nil, OnClick, OnEnter)
