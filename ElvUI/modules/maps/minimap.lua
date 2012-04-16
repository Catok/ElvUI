local E, L, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, ProfileDB, GlobalDB
local M = E:NewModule('Minimap', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');
E.Minimap = M

local calendar_string = string.gsub(SLASH_CALENDAR1, "/", "")
calendar_string = string.gsub(calendar_string, "^%l", string.upper)

local menuFrame = CreateFrame("Frame", "MinimapRightClickMenu", E.UIParent, "UIDropDownMenuTemplate")
local menuList = {
	{text = CHARACTER_BUTTON,
	func = function() ToggleCharacter("PaperDollFrame") end},
	{text = SPELLBOOK_ABILITIES_BUTTON,
	func = function() if not SpellBookFrame:IsShown() then ShowUIPanel(SpellBookFrame) else HideUIPanel(SpellBookFrame) end end},
	{text = TALENTS_BUTTON,
	func = function()
		if not PlayerTalentFrame then
			LoadAddOn("Blizzard_TalentUI")
		end

		if not GlyphFrame then
			LoadAddOn("Blizzard_GlyphUI")
		end
		PlayerTalentFrame_Toggle()
	end},
	{text = TIMEMANAGER_TITLE,
	func = function() ToggleFrame(TimeManagerFrame) end},		
	{text = ACHIEVEMENT_BUTTON,
	func = function() ToggleAchievementFrame() end},
	{text = QUESTLOG_BUTTON,
	func = function() ToggleFrame(QuestLogFrame) end},
	{text = SOCIAL_BUTTON,
	func = function() ToggleFriendsFrame(1) end},
	{text = calendar_string,
	func = function() GameTimeFrame:Click() end},
	{text = PLAYER_V_PLAYER,
	func = function() ToggleFrame(PVPFrame) end},
	{text = ACHIEVEMENTS_GUILD_TAB,
	func = function()
		if IsInGuild() then
			if not GuildFrame then LoadAddOn("Blizzard_GuildUI") end
			GuildFrame_Toggle()
		else
			if not LookingForGuildFrame then LoadAddOn("Blizzard_LookingForGuildUI") end
			if not LookingForGuildFrame then return end
			LookingForGuildFrame_Toggle()
		end
	end},
	{text = LFG_TITLE,
	func = function() ToggleFrame(LFDParentFrame) end},
	{text = RAID_FINDER,
	func = function() RaidMicroButton:Click() end},
	{text = ENCOUNTER_JOURNAL, 
	func = function() if not IsAddOnLoaded('Blizzard_EncounterJournal') then LoadAddOn('Blizzard_EncounterJournal'); end ToggleFrame(EncounterJournal) end},	
	{text = L_CALENDAR,
	func = function()
	if(not CalendarFrame) then LoadAddOn("Blizzard_Calendar") end
		Calendar_Toggle()
	end},			
	{text = HELP_BUTTON,
	func = function() ToggleHelpFrame() end},
}

--Support for other mods
function GetMinimapShape() 
	return 'SQUARE' 
end

function M:GetLocTextColor()
	local pvpType = GetZonePVPInfo()
	if pvpType == "arena" then
		return 0.84, 0.03, 0.03
	elseif pvpType == "friendly" then
		return 0.05, 0.85, 0.03
	elseif pvpType == "contested" then
		return 0.9, 0.85, 0.05
	elseif pvpType == "hostile" then 
		return 0.84, 0.03, 0.03
	elseif pvpType == "sanctuary" then
		return 0.035, 0.58, 0.84
	elseif pvpType == "combat" then
		return 0.84, 0.03, 0.03
	else
		return 0.84, 0.03, 0.03
	end	
end

function M:ADDON_LOADED(event, addon)
	if addon == "Blizzard_TimeManager" then
		TimeManagerClockButton:Kill()
	elseif addon == "Blizzard_FeedbackUI" then
		FeedbackUIButton:Kill()
	end
end

function M:Minimap_OnMouseUp(btn)
	local position = self:GetPoint()
	if btn == "MiddleButton" or (btn == "RightButton" and IsShiftKeyDown()) then
		if position:match("LEFT") then
			EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
		else
			EasyMenu(menuList, menuFrame, "cursor", -160, 0, "MENU", 2)
		end	
	elseif btn == "RightButton" then
		local xoff = -1

		if position:match("RIGHT") then xoff = E:Scale(-16) end
	
		ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self, xoff, E:Scale(-3))
	else
		Minimap_OnClick(self)
	end
end

function M:Minimap_OnMouseWheel(d)
	if d > 0 then
		_G.MinimapZoomIn:Click()
	elseif d < 0 then
		_G.MinimapZoomOut:Click()
	end
end

function M:Update_ZoneText()
	Minimap.location:SetText(strsub(GetMinimapZoneText(),1,25))
	Minimap.location:SetTextColor(M:GetLocTextColor())
end

function M:UpdateLFG()
	MiniMapLFGFrame:ClearAllPoints()
	MiniMapLFGFrame:Point("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 2, 1)
	MiniMapLFGFrameBorder:Hide()
end

function M:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	self:UpdateSettings()
end

function M:UpdateSettings()
	if InCombatLockdown() then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	end
	E.MinimapSize = E.db.general.minimapSize
	
	if E.db.general.raidReminder then
		E.RBRWidth = ((E.MinimapSize - 6) / 6) + 4
	else
		E.RBRWidth = 0;
	end
	
	E.MinimapWidth = E.MinimapSize	
	E.MinimapHeight = E.MinimapSize + 5
	Minimap:Size(E.MinimapSize, E.MinimapSize)
	
	if MMHolder then
		MMHolder:Width((Minimap:GetWidth() + 4) + E.RBRWidth)
		MMHolder:Height(Minimap:GetHeight() + 27)	
	end
	
	if Minimap.location then
		Minimap.location:Width(E.MinimapSize)
	end
	
	if MinimapMover then
		MinimapMover:Size(MMHolder:GetSize())
	end

	if AurasHolder then
		AurasHolder:Height(E.MinimapHeight)
		if AurasMover and not E:HasMoverBeenMoved('AurasMover') and not E:HasMoverBeenMoved('MinimapMover') then
			AurasMover:ClearAllPoints()
			AurasMover:Point("TOPRIGHT", E.UIParent, "TOPRIGHT", -((E.MinimapSize + 4) + E.RBRWidth + 7), -3)
			E:SaveMoverDefaultPosition('AurasMover')
		end
		
		if AurasMover then
			AurasMover:Height(E.MinimapHeight)
		end
	end
	
	if UpperRepExpBarHolder then
		E:GetModule('Misc'):UpdateExpRepBarAnchor()
	end
	
	if ElvConfigToggle then
		if E.db.general.raidReminder then
			ElvConfigToggle:Show()
			ElvConfigToggle:Width(E.RBRWidth)
		else
			ElvConfigToggle:Hide()
		end
	end
	
	if RaidBuffReminder then
		RaidBuffReminder:Width(E.RBRWidth)
		for i=1, 6 do
			RaidBuffReminder['spell'..i]:Size(E.RBRWidth - 4)
		end
		
		if E.db.general.raidReminder then
			E:GetModule('RaidBuffReminder'):EnableRBR()
		else
			E:GetModule('RaidBuffReminder'):DisableRBR()
		end
	end
end

function M:SkinMinimapButton(f)	
	f:SetPushedTexture(nil)
	f:SetHighlightTexture(nil)
	f:SetDisabledTexture(nil)
	f:SetSize(22, 22)

	for i = 1, f:GetNumRegions() do
		local region = select(i, f:GetRegions())
		if region:GetObjectType() == "Texture" then
			local tex = region:GetTexture()
			if tex and (tex:find("Border") or tex:find("Background")) then
				region:SetTexture(nil)
			else
				region:SetDrawLayer("OVERLAY", 5)
				region:ClearAllPoints()
				region:Point("TOPLEFT", f, "TOPLEFT", 2, -2)
				region:Point("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
				region:SetTexCoord(.08, .92, .08, .92)
			end
		end
		
	end
	
	Minimap:HookScript("OnEnter", function() f:SetAlpha(1) end)
	f:HookScript("OnEnter", function() f:SetAlpha(1) end)
	Minimap:HookScript("OnLeave", function() f:SetAlpha(0) end)
	f:SetTemplate("Default")
	f:SetFrameLevel(f:GetFrameLevel() + 2)
	-- Set flag to indicate that this button has already been skinned
	f.skinned = true
end

local blackList = {
	['MiniMapBattlefieldFrame'] = true,
}

function M:IsMinimapButton(f)
	if f:GetName() and blackList[f:GetName()] then
		return false;
	end
	
	for i=1, f:GetNumRegions() do
		local region = select(i, f:GetRegions())
		if region:GetObjectType() == 'Texture' then
			local tex = region:GetTexture()
			if tex then
				tex = string.lower(tex)
				if tex:find('trackingborder') or tex:find('minimap') then
					return true
				end
			end
		end
	end
	return false
end

function M:CheckForNewMinimapButtons()
	for i = 1, Minimap:GetNumChildren() do
		local f = select(i, Minimap:GetChildren())
		if not f.skinned and f:GetObjectType() == 'Button' and self:IsMinimapButton(f) then
			self:SkinMinimapButton(f)
		end
	end
end

function M:Initialize()	
	self:ScheduleRepeatingTimer('CheckForNewMinimapButtons', 15)
	self:CheckForNewMinimapButtons() --Initial check
	self:RegisterEvent('ADDON_LOADED', 'CheckForNewMinimapButtons') --Gotta catch em all
	
	local mmholder = CreateFrame('Frame', 'MMHolder', Minimap)
	mmholder:Point("TOPRIGHT", E.UIParent, "TOPRIGHT", -3, -3)
	mmholder:Width((Minimap:GetWidth() + 29) + E.RBRWidth)
	mmholder:Height(Minimap:GetHeight() + 53)
	
	Minimap:ClearAllPoints()
	Minimap:Point("TOPLEFT", mmholder, "TOPLEFT", 2, -2)
	Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')
	Minimap:CreateBackdrop('Default')
	Minimap:HookScript('OnEnter', function(self)
		self.location:Show()
	end)
	
	Minimap:HookScript('OnLeave', function(self)
		self.location:Hide()
	end)	
	
	--Fix spellbook taint
	ShowUIPanel(SpellBookFrame)
	HideUIPanel(SpellBookFrame)	
	
	Minimap.location = Minimap:CreateFontString(nil, 'OVERLAY')
	Minimap.location:FontTemplate(nil, nil, 'OUTLINE')
	Minimap.location:Point('TOP', Minimap, 'TOP', 0, -2)
	Minimap.location:SetJustifyH("CENTER")
	Minimap.location:SetJustifyV("MIDDLE")		
	Minimap.location:Hide()
	
	LFGSearchStatus:SetTemplate("Default")
	LFGSearchStatus:SetClampedToScreen(true)
	LFGDungeonReadyStatus:SetClampedToScreen(true)	
	
	MinimapBorder:Hide()
	MinimapBorderTop:Hide()

	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()

	MiniMapVoiceChatFrame:Hide()

	MinimapNorthTag:Kill()

	GameTimeFrame:Hide()

	MinimapZoneTextButton:Hide()

	MiniMapTracking:Hide()

	MiniMapMailFrame:ClearAllPoints()
	MiniMapMailFrame:Point("TOPRIGHT", Minimap, 3, 4)
	MiniMapMailBorder:Hide()
	MiniMapMailIcon:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\mail")

	MiniMapBattlefieldFrame:ClearAllPoints()
	MiniMapBattlefieldFrame:Point("BOTTOMRIGHT", Minimap, 3, 0)
	MiniMapBattlefieldBorder:Hide()

	MiniMapWorldMapButton:Hide()

	MiniMapInstanceDifficulty:ClearAllPoints()
	MiniMapInstanceDifficulty:SetParent(Minimap)
	MiniMapInstanceDifficulty:Point("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

	GuildInstanceDifficulty:ClearAllPoints()
	GuildInstanceDifficulty:SetParent(Minimap)
	GuildInstanceDifficulty:Point("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
	
	if TimeManagerClockButton then
		TimeManagerClockButton:Kill()
	end
	
	if FeedbackUIButton then
		FeedbackUIButton:Kill()
	end
	
	E:CreateMover(MMHolder, 'MinimapMover', 'Minimap', nil, nil)
	Minimap.SetPoint = E.noop;
	MMHolder.SetPoint = E.noop;
	Minimap.ClearAllPoints = E.noop;
	MMHolder.ClearAllPoints = E.noop;	
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", M.Minimap_OnMouseWheel)	
	Minimap:SetScript("OnMouseUp", M.Minimap_OnMouseUp)
	
	MiniMapLFGFrame:ClearAllPoints()
	MiniMapLFGFrame:Point("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 2, 1)
	MiniMapLFGFrameBorder:Hide()	
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update_ZoneText")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "Update_ZoneText")
	self:RegisterEvent("ZONE_CHANGED", "Update_ZoneText")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "Update_ZoneText")		
	self:RegisterEvent('ADDON_LOADED')
	self:UpdateSettings()
	
	--Create Farmmode Minimap
	local fm = CreateFrame('Minimap', 'FarmModeMap', E.UIParent)
	fm:Size(E.db.farmSize)
	fm:Point('TOP', E.UIParent, 'TOP', 0, -120)
	
	fm:CreateBackdrop('Default')
	fm:EnableMouseWheel(true)
	fm:SetScript("OnMouseWheel", M.Minimap_OnMouseWheel)	
	fm:SetScript("OnMouseUp", M.Minimap_OnMouseUp)	
	fm:RegisterForDrag("LeftButton", "RightButton")
	fm:SetMovable(true)
	fm:SetScript("OnDragStart", function(self) self:StartMoving() end)
	fm:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	fm:Hide()
	
	FarmModeMap:SetScript('OnShow', function() 	
		if not E:HasMoverBeenMoved('AurasMover') then
			AurasMover:ClearAllPoints()
			AurasMover:Point("TOPRIGHT", E.UIParent, "TOPRIGHT", -3, -3)
		end
		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetAllPoints(FarmModeMap)
		if IsAddOnLoaded('Routes') then
			LibStub("AceAddon-3.0"):GetAddon('Routes'):ReparentMinimap(FarmModeMap)
		end

		if IsAddOnLoaded('GatherMate2') then
			LibStub('AceAddon-3.0'):GetAddon('GatherMate2'):GetModule('Display'):ReparentMinimapPins(FarmModeMap)
		end		
	end)
	
	FarmModeMap:SetScript('OnHide', function() 
		if not E:HasMoverBeenMoved('AurasMover') then
			E:ResetMovers('Auras Frame')
		end	
		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetAllPoints(Minimap)	
		if IsAddOnLoaded('Routes') then
			LibStub("AceAddon-3.0"):GetAddon('Routes'):ReparentMinimap(Minimap)
		end

		if IsAddOnLoaded('GatherMate2') then
			LibStub('AceAddon-3.0'):GetAddon('GatherMate2'):GetModule('Display'):ReparentMinimapPins(Minimap)
		end	
	end)

	
	UIParent:HookScript('OnShow', function()
		FarmModeMap:Hide()
	end)
end

E:RegisterModule(M:GetName())