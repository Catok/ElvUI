local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule('DataTexts')

local lastPanel
local displayString = ''
local classColor = RAID_CLASS_COLORS[E.myclass]
local dataLayout = {
	['LeftChatDataPanel'] = {
		['left'] = 10,
		['middle'] = 5,
		['right'] = 2,
	},
	['RightChatDataPanel'] = {
		['left'] = 4,
		['middle'] = 3,
		['right'] = 11,
	},	
}

local dataStrings = {
	[10] = DAMAGE..' '..DONE,
	[5] = HONOR,
	[2] = KILLING_BLOWS,
	[4] = DEATHS,
	[3] = HONORABLE_KILLS,
	[11] = SHOW_COMBAT_HEALING..' '..DONE,
}

local WSG = 443
local TP = 626
local AV = 401
local SOTA = 512
local IOC = 540
local EOTS = 482
local TBFG = 736
local AB = 461

function DT:UPDATE_BATTLEFIELD_SCORE()
	lastPanel = self
	local index = dataLayout[self:GetParent():GetName()][self.pointIndex]
	for i=1, GetNumBattlefieldScores() do
		if select(1, GetBattlefieldScore(i)) == E.myname then
			self.text:SetFormattedText(displayString, dataStrings[index], E:ShortValue(select(index, GetBattlefieldScore(i))))
		end
	end
end

function DT:BattlegroundStats()
	DT:SetupTooltip(self)
	local CurrentMapID = GetCurrentMapAreaID()
	
	for index=1, GetNumBattlefieldScores() do
		local name = GetBattlefieldScore(index)
		if name and name == E.myname then
			GameTooltip:AddDoubleLine(L['Stats For:'], name, 1,1,1, classColor.r, classColor.g, classColor.b)
			GameTooltip:AddLine(" ")

			--Add extra statistics to watch based on what BG you are in.
			if CurrentMapID == WSG or CurrentMapID == TP then 
				GameTooltip:AddDoubleLine(L['Flags Captured'], GetBattlefieldStatData(index, 1),1,1,1)
				GameTooltip:AddDoubleLine(L['Flags Returned'], GetBattlefieldStatData(index, 2),1,1,1)
			elseif CurrentMapID == EOTS then
				GameTooltip:AddDoubleLine(L['Flags Captured'], GetBattlefieldStatData(index, 1),1,1,1)
			elseif CurrentMapID == AV then
				GameTooltip:AddDoubleLine(L['Graveyards Assaulted'], GetBattlefieldStatData(index, 1),1,1,1)
				GameTooltip:AddDoubleLine(L['Graveyards Defended'], GetBattlefieldStatData(index, 2),1,1,1)
				GameTooltip:AddDoubleLine(L['Towers Assaulted'], GetBattlefieldStatData(index, 3),1,1,1)
				GameTooltip:AddDoubleLine(L['Towers Defended'], GetBattlefieldStatData(index, 4),1,1,1)
			elseif CurrentMapID == SOTA then
				GameTooltip:AddDoubleLine(L['Demolishers Destroyed'], GetBattlefieldStatData(index, 1),1,1,1)
				GameTooltip:AddDoubleLine(L['Gates Destroyed'], GetBattlefieldStatData(index, 2),1,1,1)
			elseif CurrentMapID == IOC or CurrentMapID == TBFG or CurrentMapID == AB then
				GameTooltip:AddDoubleLine(L['Bases Assaulted'], GetBattlefieldStatData(index, 1),1,1,1)
				GameTooltip:AddDoubleLine(L['Bases Defended'], GetBattlefieldStatData(index, 2),1,1,1)
			end		
		end
	end	
	
	GameTooltip:Show()
end

function DT:HideBattlegroundTexts()
	DT.ForceHideBGStats = true
	DT:LoadDataTexts()
	E:Print(L['Battleground datatexts temporarily hidden, to show type /bgstats or right click the "C" icon near the minimap.'])
end

local function ValueColorUpdate(hex, r, g, b)
	displayString = string.join("", "%s: ", hex, "%s|r")

	if lastPanel ~= nil then
		DT.UPDATE_BATTLEFIELD_SCORE(lastPanel)
	end
end
E['valueColorUpdateFuncs'][ValueColorUpdate] = true