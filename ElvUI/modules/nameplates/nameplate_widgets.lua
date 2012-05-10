local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:GetModule('NamePlates')

--[[
	This file handles functions for the Castbar and aura modules of nameplates.
]]
NP.GroupMembers = {};
NP.CachedAuraDurations = {};
NP.AuraCache = {}
NP.RaidTargetReference = {
	["STAR"] = 0x00000001,
	["CIRCLE"] = 0x00000002,
	["DIAMOND"] = 0x00000004,
	["TRIANGLE"] = 0x00000008,
	["MOON"] = 0x00000010,
	["SQUARE"] = 0x00000020,
	["CROSS"] = 0x00000040,
	["SKULL"] = 0x00000080,
}

local AURA_TYPE_BUFF = 1
local AURA_TYPE_DEBUFF = 6
local AURA_TARGET_HOSTILE = 1
local AURA_TARGET_FRIENDLY = 2
local AuraList, AuraGUID = {}, {}
NP.MAX_DISPLAYABLE_AURAS = 5

local AURA_TYPE = {
	["Buff"] = 1,
	["Curse"] = 2,
	["Disease"] = 3,
	["Magic"] = 4,
	["Poison"] = 5,
	["Debuff"] = 6,
}

NP.RaidIconCoordinate = {
	[0]		= { [0]		= "STAR", [0.25]	= "MOON", },
	[0.25]	= { [0]		= "CIRCLE", [0.25]	= "SQUARE",	},
	[0.5]	= { [0]		= "DIAMOND", [0.25]	= "CROSS", },
	[0.75]	= { [0]		= "TRIANGLE", [0.25]	= "SKULL", }, 
}

local RaidIconIndex = {
	"STAR",
	"CIRCLE",
	"DIAMOND",
	"TRIANGLE",
	"MOON",
	"SQUARE",
	"CROSS",
	"SKULL",
}

NP.TargetOfGroupMembers = {}
NP.ByRaidIcon = {}			-- Raid Icon to GUID 		-- ex.  ByRaidIcon["SKULL"] = GUID
NP.ByName = {}				-- Name to GUID (PVP)
NP.Aura_List = {}	-- Two Dimensional
NP.Aura_Spellid = {}
NP.Aura_Expiration = {}
NP.Aura_Stacks = {}
NP.Aura_Caster = {}
NP.Aura_Duration = {}
NP.Aura_Texture = {}
NP.Aura_Type = {}
NP.Aura_Target = {}
NP.GUIDLockouts = {}
NP.GUIDDR = {}
NP.resetDRTime = 18 --Time it tacks for DR to reset.

do
	local PolledHideIn
	local Framelist = {}			-- Key = Frame, Value = Expiration Time
	local Watcherframe = CreateFrame("Frame")
	local WatcherframeActive = false
	local select = select
	local timeToUpdate = 0
	
	local function CheckFramelist(self)
		local curTime = GetTime()
		if curTime < timeToUpdate then return end
		local framecount = 0
		timeToUpdate = curTime + 0.1
		-- Cycle through the watchlist, hiding frames which are timed-out
		for frame, auraData in pairs(Framelist) do
			if auraData.e ~= -1 and auraData.e < curTime then -- If expired...
				frame:Hide()
				Framelist[frame] = nil
			else  -- If active...
				-- Update the frame
				if frame.Poll then frame.Poll(NP, frame, auraData.e, auraData.d) end
				framecount = framecount + 1 
			end
		end
		-- If no more frames to watch, unregister the OnUpdate script
		if framecount == 0 then Watcherframe:SetScript("OnUpdate", nil); WatcherframeActive = false end
	end
	
	function PolledHideIn(frame, expiration, duration)
		if frame then
			if expiration == 0 then 
				
				frame:Hide()
				Framelist[frame] = nil
			else
				--print("Hiding in", expiration - GetTime())
				Framelist[frame] = {e = expiration, d = duration}
				frame:Show()
				
				if not WatcherframeActive then 
					Watcherframe:SetScript("OnUpdate", CheckFramelist)
					WatcherframeActive = true
				end
			end
		end
	end
	
	NP.PolledHideIn = PolledHideIn
end

local function DefaultFilterFunction(aura) 
	if (aura.duration < 600) then
		return true
	end
end

function NP:CreateAuraIcon(parent)
	local noscalemult = E.mult * UIParent:GetScale()
	local button = CreateFrame("Frame",nil,parent)
	button:SetWidth(20)
	button:SetHeight(20)
	button:SetScript('OnHide', function()
		if parent.guid then
			NP:UpdateIconGrid(parent, parent.guid)
		end
	end)
	
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetTexture(unpack(E["media"].backdropcolor))
	button.bg:SetAllPoints(button)
	
	button.bord = button:CreateTexture(nil, "BACKGROUND")
	button.bord:SetDrawLayer('BACKGROUND', 2)
	button.bord:SetTexture(unpack(E["media"].bordercolor))
	button.bord:SetPoint("TOPLEFT",button,"TOPLEFT", noscalemult,-noscalemult)
	button.bord:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-noscalemult,noscalemult)
	
	button.bg2 = button:CreateTexture(nil, "BACKGROUND")
	button.bg2:SetDrawLayer('BACKGROUND', 3)
	button.bg2:SetTexture(unpack(E["media"].backdropcolor))
	button.bg2:SetPoint("TOPLEFT",button,"TOPLEFT", noscalemult*2,-noscalemult*2)
	button.bg2:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-noscalemult*2,noscalemult*2)	
	
	button.Icon = button:CreateTexture(nil, "BORDER")
	button.Icon:SetPoint("TOPLEFT",button,"TOPLEFT", noscalemult*3,-noscalemult*3)
	button.Icon:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-noscalemult*3,noscalemult*3)
	
	button.TimeLeft = button:CreateFontString(nil, 'OVERLAY')
	button.TimeLeft:SetPoint('CENTER', button, 'CENTER', 1, 0)
	button.TimeLeft:FontTemplate(nil, 7, 'OUTLINE')
	button.TimeLeft:SetShadowColor(0, 0, 0, 0)
	
	button.Stacks = button:CreateFontString(nil,"OVERLAY")
	button.Stacks:FontTemplate(nil,7,'OUTLINE')
	button.Stacks:SetShadowColor(0, 0, 0, 0)
	button.Stacks:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 2)
	
	button.AuraInfo = {	
		Name = "",
		Icon = "",
		Stacks = 0,
		Expiration = 0,
		Duration = 0,
		Type = "",
	}			

	button.Poll = parent.PollFunction
	button:Hide()
	
	return button
end

function NP:UpdateAuraTime(frame, expiration, duration)
	local timeLeft = expiration - GetTime()
	
	if timeLeft > 60 then 
		frame.TimeLeft:SetText(ceil(timeLeft/60).."m")
	else
		if E.db.nameplate['preciseTimer'] and timeLeft < 3 then
			frame.TimeLeft:SetText(format("%.1f", timeLeft))
		else
			frame.TimeLeft:SetText(ceil(timeLeft))
		end
	end

	-- Time Left
	local textColor = {r = 1, g = 1, b = 1}
	
	if E.db.nameplate['colorByTime'] then
		local percentage = (timeLeft / duration) * 100
		
		if percentage >= 50 then
			--green to yellow
			textColor.g	= 1
			textColor.r = ((100 - percentage) / 100) * 2
		else
			--yellow to red
			textColor.r	= 1
			textColor.g = ((100 - (100 - percentage)) / 100) * 2
		end
		
		textColor.b = 0
	elseif E.db.nameplate['timerColor'] then
		textColor = E.db.nameplate['timerColor']
	end
	
	-- Flashing
	local flashTime = 0
	
	if spell and spell['flashTime'] then
		flashTime = spell['flashTime']
	elseif E.global['nameplate']['spellListDefault']['flashTime'] then
		flashTime = E.global['nameplate']['spellListDefault']['flashTime']
	end
	
	if timeLeft <= flashTime and duration >= flashTime then 
		if not UIFrameIsFlashing(frame) then
			UIFrameFlash(frame, 0.5, 0.5, timeLeft, false, 0.3, 0.01, 1)
		end
	else
		if UIFrameIsFlashing(frame) then
			UIFrameFlashStop(frame)
			frame:SetAlpha(1)
		end
	end
	
	frame.TimeLeft:SetTextColor(textColor.r, textColor.g, textColor.b, 1)
end

function NP:ClearAuraContext(frame)
	--if frame.guidcache then 
	--	AuraGUID[frame.guidcache] = nil 
	frame.guidcache = nil
	frame.unit = nil
	--end
	AuraList[frame] = nil
end

function NP:UpdateAuraContext(frame)
	local parent = frame:GetParent()
	local guid = parent.guid
	frame.unit = parent.unit
	frame.guidcache = guid
	
	AuraList[frame] = true
	if guid then AuraGUID[guid] = frame end
	
	if parent.isTarget then UpdateAurasByUnitID("target")
	elseif parent.isMouseover then UpdateAurasByUnitID("mouseover") end
	
	local raidicon, name
	if parent.isMarked then
		raidicon = parent.raidIconType
		if guid and raidicon then ByRaidIcon[raidicon] = guid end
	end
	
	
	local frame = NP:SearchForFrame(guid, raidicon, parent.hp.name:GetText())
	if frame then
		NP:UpdateAuras(frame)
	end
end

function NP.UpdateAuraTarget(frame)
	NP:UpdateIconGrid(frame, UnitGUID("target"))
end

function NP:CheckRaidIcon(frame)
	frame.isMarked = frame.raidicon:IsShown() or false
	
	if frame.isMarked then
		local ux, uy = frame.raidicon:GetTexCoord()
		frame.raidIconType = NP.RaidIconCoordinate[ux][uy]	
	else
		frame.isMarked = nil;
		frame.raidIconType = nil;
	end
end

function NP:SearchNameplateByGUID(guid)
	for frame, _ in pairs(NP.Handled) do
		frame = _G[frame]
		if frame and frame:IsShown() and frame.guid == guid then
			return frame
		end
	end
end

function NP:SearchNameplateByName(sourceName)
	if not sourceName then return; end
	local SearchFor = strsplit("-", sourceName)
	for frame, _ in pairs(NP.Handled) do
		frame = _G[frame]
		if frame and frame:IsShown() and frame.hp.name:GetText() == SearchFor and frame.hasClass then
			return frame
		end
	end
end

function NP:SearchNameplateByIcon(UnitFlags)
	local UnitIcon
	for iconname, bitmask in pairs(NP.RaidTargetReference) do
		if bit.band(UnitFlags, bitmask) > 0  then
			UnitIcon = iconname
			break
		end
	end	

	for frame, _ in pairs(NP.Handled) do
		frame = _G[frame]
		if frame and frame:IsShown() and frame.isMarked and (frame.raidIconType == UnitIcon) then
			return frame
		end
	end	
end

function NP:SearchNameplateByIconName(raidicon)
	local frame
	for frame, _ in pairs(NP.Handled) do
		frame = _G[frame]
		if frame and frame:IsShown() and frame.isMarked and (frame.raidIconType == raidIcon) then
			return frame
		end
	end		
end

function NP:SearchForFrame(guid, raidicon, name)
	local frame

	if guid then frame = self:SearchNameplateByGUID(guid) end
	if (not frame) and name then frame = self:SearchNameplateByName(name) end
	if (not frame) and raidicon then frame = self:SearchNameplateByIconName(raidicon) end
	
	return frame
end

function NP:SetAuraInstance(guid, spellid, expiration, stacks, caster, duration, texture, auratype, auratarget, overrideDR)
	local filter = false
	local name = GetSpellInfo(spellid)
	
	if auratype == -1 then
		name = "School Lockout";
	end
	
	local visibility = E.global['nameplate']['spellListDefault']['visibility']
	if visibility  == 1 or (visibility == 3 and caster == UnitGUID('player')) then
		filter = true;
	end
	
	local spellList = E.global['nameplate']['spellList']
	if spellList[name] then--and spellList[name].enable then
		visibility = spellList[name]['visibility']
		if visibility  == 1 or (visibility == 3 and caster == UnitGUID('player')) then
			filter = true;
		else
			filter = false;
		end
	end
	
	if filter ~= true then
		return;
	end

	if guid and spellid and texture then
		if GetPlayerInfoByGUID(guid) then
			local DRType = NP.drSpells[spellid]
			
			if DRType and not overrideDR then
				local newDR = { diminish = 0.5, DRExpire = GetTime() + NP.resetDRTime }
				
				if NP.GUIDDR[guid] and NP.GUIDDR[guid][DRType] then
					if NP.GUIDDR[guid][DRType].DRExpire < GetTime() then
						NP.GUIDDR[guid][DRType].DRExpire = GetTime() + NP.resetDRTime
						NP.GUIDDR[guid][DRType].diminish = 0.5
					elseif NP.GUIDDR[guid][DRType].diminish >= 0.25 then
						NP.GUIDDR[guid][DRType].DRExpire = GetTime() + NP.resetDRTime
						duration = duration * NP.GUIDDR[guid][DRType].diminish
						NP.GUIDDR[guid][DRType].diminish = NP.GUIDDR[guid][DRType].diminish / 2
					else
						-- This shouldn't happen
					end
				elseif NP.GUIDDR[guid] and not NP.GUIDDR[guid][DRType] then
					NP.GUIDDR[guid][DRType] = newDR
				else
					NP.GUIDDR[guid] = { }
					tinsert(NP.GUIDDR[guid], { DRType = newDR })
				end
			end
		end
		
		--Special check for BG flags
		if spellid == 14267 or spellid == 14268 or spellid == 34976 then
			NP:WipeAura(spellid)
		end
	
		local aura_id = spellid..(tostring(caster or "UNKNOWN_CASTER"))
		local aura_instance_id = guid..aura_id
		NP.Aura_List[guid] = NP.Aura_List[guid] or {}
		NP.Aura_List[guid][aura_id] = aura_instance_id
		NP.Aura_Spellid[aura_instance_id] = spellid
		NP.Aura_Expiration[aura_instance_id] = expiration
		NP.Aura_Stacks[aura_instance_id] = stacks
		NP.Aura_Caster[aura_instance_id] = caster
		NP.Aura_Duration[aura_instance_id] = duration
		NP.Aura_Texture[aura_instance_id] = texture
		NP.Aura_Type[aura_instance_id] = auratype
		NP.Aura_Target[aura_instance_id] = auratarget
	end
end

function NP:RemoveAuraInstance(guid, spellid, caster)
	if guid and spellid and NP.Aura_List[guid] then
		local aura_instance_id = tostring(guid)..tostring(spellid)..(tostring(caster or "UNKNOWN_CASTER"))
		local aura_id = spellid..(tostring(caster or "UNKNOWN_CASTER"))
		if NP.Aura_List[guid][aura_id] then
			NP.Aura_Spellid[aura_instance_id] = nil
			NP.Aura_Expiration[aura_instance_id] = nil
			NP.Aura_Stacks[aura_instance_id] = nil
			NP.Aura_Caster[aura_instance_id] = nil
			NP.Aura_Duration[aura_instance_id] = nil
			NP.Aura_Texture[aura_instance_id] = nil
			NP.Aura_Type[aura_instance_id] = nil
			NP.Aura_Target[aura_instance_id] = nil
			NP.Aura_List[guid][aura_id] = nil
		end
	end
end

function NP:UpdateAuraByLookup(guid, name)
 	if guid == UnitGUID("target") then
		NP:UpdateAurasByUnitID("target")
	elseif guid == UnitGUID("mouseover") then
		NP:UpdateAurasByUnitID("mouseover")
	elseif self.TargetOfGroupMembers[guid] then
		local unit = self.TargetOfGroupMembers[guid]
		if unit then
			local unittarget = UnitGUID(unit.."target")
			if guid == unittarget then
				NP:UpdateAurasByUnitID(unittarget)
			end
		end	
	else
		NP:UpdateAurasByGUID(guid, name)
	end
end

function NP:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, ...)
	local _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellid, spellName, _, auraType, stackCount, extraSchool  = ...
	local isPvP = false
	
	if bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 and bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then
		isPvP = true
	end
	
	local shortDestName = NP:RemoveServerName(destName)
	local shortSourceName = NP:RemoveServerName(sourceName)
	
	-- Cache Unit Name for alternative lookup strategy
	if shortDestName and destGUID and bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 and not NP.ByName[shortDestName] then 
		NP.ByName[shortDestName] = destGUID
	end
	if shortSourceName and sourceGUID and bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 and not NP.ByName[shortSourceName] then 
		NP.ByName[shortSourceName] = sourceGUID
	end
	
	if event == "SPELL_INTERRUPT" and NP.lockouts[spellid] then
		local texture = GetSpellTexture(spellid)
		if not NP.GUIDLockouts[destGUID] then
			NP.GUIDLockouts[destGUID] = {  }
		end
		NP.GUIDLockouts[destGUID][extraSchool] = { dest = destGUID, source = sourceGUID, destSpell = auraType, sourceSpell = spellid, expire = GetTime() + NP.lockouts[spellid], dur = NP.lockouts[spellid], tex = texture }
		NP:SetAuraInstance(destGUID, auraType, GetTime() + NP.lockouts[spellid], 1, sourceGUID, NP.lockouts[spellid], texture, -1, AURA_TARGET_HOSTILE, true)
	end
	
	if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
		local duration = NP:GetSpellDuration(spellid, isPvP)
		local expiration = 0
		local texture = GetSpellTexture(spellid)
		
		if duration > 0 then
			expiration = duration + GetTime()
		end
		
		if duration ~= -1 then
			NP:SetAuraInstance(destGUID, spellid, expiration, 1, sourceGUID, duration, texture, AURA_TYPE_DEBUFF, AURA_TARGET_HOSTILE, false)
		end
	elseif event == "SPELL_AURA_APPLIED_DOSE" or event == "SPELL_AURA_REMOVED_DOSE" then
		local duration = NP:GetSpellDuration(spellid, isPvP)
		local expiration = 0
		local texture = GetSpellTexture(spellid)
		
		if duration > 0 then
			expiration = duration + GetTime()
		end
		
		if duration ~= -1 then
			NP:SetAuraInstance(destGUID, spellid, expiration, stackCount, sourceGUID, duration, texture, AURA_TYPE_DEBUFF, AURA_TARGET_HOSTILE, false)
		end
	elseif event == "SPELL_AURA_BROKEN" or event == "SPELL_AURA_BROKEN_SPELL" or event == "SPELL_AURA_REMOVED" then
		NP:RemoveAuraInstance(destGUID, spellid, sourceGUID)
	elseif event == "SPELL_CAST_START" then
		local FoundPlate = nil;
		-- Gather Spell Info

		local spell, _, icon, _, _, _, castTime, _, _ = GetSpellInfo(spellid)
		if not (castTime > 0) then return end		
		if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then 
			if bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then 
				--	destination plate, by name
				FoundPlate = NP:SearchNameplateByName(sourceName)
			elseif bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0 then 
				--	destination plate, by GUID
				FoundPlate = NP:SearchNameplateByGUID(sourceGUID)
				if not FoundPlate then 
					FoundPlate = NP:SearchNameplateByIcon(sourceRaidFlags) 
				end
			else 
				return	
			end
		else 
			return 
		end	
		
		if not FoundPlate or not FoundPlate:IsShown() then return; end
		
		if FoundPlate.unit == 'mouseover' then
			NP:UpdateCastInfo('UPDATE_MOUSEOVER_UNIT', true)	
		elseif FoundPlate.unit == 'target' then
			NP:UpdateCastInfo('PLAYER_TARGET_CHANGED')
		else
			FoundPlate.guid = sourceGUID
			local currentTime = GetTime() * 1e3
			NP:StartCastAnimationOnNameplate(FoundPlate, spell, spellid, icon, currentTime, currentTime + castTime, false, false)
		end		
	elseif event == "SPELL_CAST_FAILED" or event == "SPELL_INTERRUPT" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_HEAL" then
		local FoundPlate = nil;
		if sourceGUID == UnitGUID('player') and event == "SPELL_CAST_FAILED" then return; end
		if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then 
			if bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then 
				--	destination plate, by name
				FoundPlate = NP:SearchNameplateByName(sourceName)
			elseif bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0 then 
				--	destination plate, by GUID
				FoundPlate = NP:SearchNameplateByGUID(sourceGUID)
				if not FoundPlate then 
					FoundPlate = NP:SearchNameplateByIcon(sourceRaidFlags) 
				end
			else 
				return	
			end
		else 
			return 
		end	

		if FoundPlate and FoundPlate:IsShown() then 
			FoundPlate.guid = sourceGUID
			NP:StopCastAnimation(FoundPlate)
		end		
	else
		if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then 
			if bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then 
				--	destination plate, by name
				FoundPlate = NP:SearchNameplateByName(sourceName)
			elseif bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0 then 
				--	destination plate, by raid icon
				FoundPlate = NP:SearchNameplateByIcon(sourceRaidFlags) 
			else 
				return	
			end
		else 
			return 
		end	
		
		if FoundPlate and FoundPlate:IsShown() and FoundPlate.unit ~= "target" then 
			FoundPlate.guid = sourceGUID
		end			
	end

	if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED_DOSE" or event == "SPELL_AURA_REMOVED_DOSE" or event == "SPELL_AURA_BROKEN" or event == "SPELL_AURA_BROKEN_SPELL" or event == "SPELL_AURA_REMOVED" then	
		NP:UpdateAuraByLookup(destGUID, shortDestName)
		
		-- Cache Raid Icon Data for alternative lookup strategy
		for iconname, bitmask in pairs(NP.RaidTargetReference) do
			if bit.band(destRaidFlags, bitmask) > 0  then
				NP.ByRaidIcon[iconname] = destGUID
				raidicon = iconname
				break
			end
		end			
	end	
	
end

function NP:PLAYER_REGEN_ENABLED()
	if self.db.combat then
		SetCVar("nameplateShowEnemies", 0)
	end
	
	self:CleanAuraLists()
end

function NP:PLAYER_REGEN_DISABLED()
	if self.db.combat then
		SetCVar("nameplateShowEnemies", 1)
	end
end

function NP:UpdateCastInfo(event, ignoreInt)
	local unit = 'target'
	if event == 'UPDATE_MOUSEOVER_UNIT' then
		unit = 'mouseover'
	end
	
	local GUID = UnitGUID(unit)
	if not GUID then return; end

	if not ignoreInt then
		NP:UpdateAurasByUnitID(unit)
	end
	
	local targetPlate = NP:SearchNameplateByGUID(GUID)
	local channel
	local spell, _, name, icon, start, finish, _, spellid, nonInt = UnitCastingInfo(unit)
	
	if not spell then 
		spell, _, name, icon, start, finish, spellid, nonInt = UnitChannelInfo(unit); 
		channel = true 
	end	
	
	if event == 'UPDATE_MOUSEOVER_UNIT' then
		nonInt = false
	end

	if spell and targetPlate then 
		NP:StartCastAnimationOnNameplate(targetPlate, spell, spellid, icon, start, finish, nonInt, channel) 
	elseif targetPlate then
		NP:StopCastAnimation(targetPlate) 
	end
end

function NP:CleanAuraLists()	
	local currentTime = GetTime()
	for guid, instance_list in pairs(NP.Aura_List) do
		local auracount = 0
		for aura_id, aura_instance_id in pairs(instance_list) do
			local expiration = NP.Aura_Expiration[aura_instance_id]
			if expiration and expiration < currentTime and expiration ~= 0 then
				--print("Cleaned "..NP.Aura_Spellid[aura_instance_id].." Exp was "..expiration)
				NP.Aura_List[guid][aura_id] = nil
				NP.Aura_Spellid[aura_instance_id] = nil
				NP.Aura_Expiration[aura_instance_id] = nil
				NP.Aura_Stacks[aura_instance_id] = nil
				NP.Aura_Caster[aura_instance_id] = nil
				NP.Aura_Duration[aura_instance_id] = nil
				NP.Aura_Texture[aura_instance_id] = nil
				NP.Aura_Type[aura_instance_id] = nil
				NP.Aura_Target[aura_instance_id] = nil
			else
				auracount = auracount + 1
			end
		end
		if auracount == 0 then
			NP.Aura_List[guid] = nil
		end
	end
end

function NP:UpdateRoster()
	local groupType, groupSize, unitId, unitName
	if UnitInRaid("player") then 
		groupType = "raid"
		groupSize = GetNumRaidMembers() - 1
	elseif UnitInParty("player") then 
		groupType = "party"
		groupSize = GetNumPartyMembers() 
	else 
		groupType = "solo"
		groupSize = 1
	end
	
	wipe(self.GroupMembers)
	
	-- Cycle through Group
	if groupType then
		for index = 1, groupSize do
			unitId = groupType..index	
			unitName = UnitName(unitId)
			if unitName then
				self.GroupMembers[unitName] = unitId
			end
		end
	end	
end

function NP:WipeAuraList(guid)
	if guid and self.Aura_List[guid] then
		local unit_aura_list = self.Aura_List[guid]
		for aura_id, aura_instance_id in pairs(unit_aura_list) do
			self.Aura_Spellid[aura_instance_id] = nil
			self.Aura_Expiration[aura_instance_id] = nil
			self.Aura_Stacks[aura_instance_id] = nil
			self.Aura_Caster[aura_instance_id] = nil
			self.Aura_Duration[aura_instance_id] = nil
			self.Aura_Texture[aura_instance_id] = nil
			self.Aura_Type[aura_instance_id] = nil
			self.Aura_Target[aura_instance_id] = nil
			unit_aura_list[aura_id] = nil
		end
	end
end

function NP:WipeAura(spellid)
	for guid, unit_aura_list in pairs(self.Aura_List) do 
		for aura_id, aura_instance_id in pairs(unit_aura_list) do
			if self.Aura_Spellid[aura_instance_id] == spellid then
				self.Aura_Spellid[aura_instance_id] = nil
				self.Aura_Expiration[aura_instance_id] = nil
				self.Aura_Stacks[aura_instance_id] = nil
				self.Aura_Caster[aura_instance_id] = nil
				self.Aura_Duration[aura_instance_id] = nil
				self.Aura_Texture[aura_instance_id] = nil
				self.Aura_Type[aura_instance_id] = nil
				self.Aura_Target[aura_instance_id] = nil
				unit_aura_list[aura_id] = nil
			end
		end
	end
end

function NP:GetSpellDuration(spellid, pvp)
	if NP.auraInfoPvP[spellid] and pvp then
		return NP.auraInfoPvP[spellid]
	elseif NP.auraInfo[spellid] then
		return NP.auraInfo[spellid]
	elseif NP.CachedAuraDurations[spellid] then
		return NP.CachedAuraDurations[spellid]
	else
		return -1
	end
end

function NP:SetSpellDuration(spellid, duration)
	if spellid and not NP.auraInfo[spellid] then 
		NP.CachedAuraDurations[spellid] = duration
	end
end

function NP:GetAuraList(guid)
	if guid and self.Aura_List[guid] then return self.Aura_List[guid] end
end

function NP:GetAuraInstance(guid, aura_id)
	if guid and aura_id then
		local aura_instance_id = guid..aura_id
		local spellid, expiration, stacks, caster, duration, texture, auratype
		spellid = self.Aura_Spellid[aura_instance_id]
		expiration = self.Aura_Expiration[aura_instance_id]
		stacks = self.Aura_Stacks[aura_instance_id]
		caster = self.Aura_Caster[aura_instance_id]
		duration = self.Aura_Duration[aura_instance_id]
		texture = self.Aura_Texture[aura_instance_id]
		auratype  = self.Aura_Type[aura_instance_id]
		auratarget  = self.Aura_Target[aura_instance_id]
		return spellid, expiration, stacks, caster, duration, texture, auratype, auratarget
	end
end

function NP:UpdateIcon(frame, texture, expiration, stacks, duration, name)

	if frame and texture and name then
		local spell = E.global['nameplate']['spellList'][name]
		
		-- Icon
		frame.Icon:SetTexture(texture)
		
		-- Size
		local width = 20
		local height = 20
		
		if spell and spell['width'] then
			width = spell['width']
		elseif E.global['nameplate']['spellListDefault']['width'] then
			width = E.global['nameplate']['spellListDefault']['width']
		end
		
		if spell and spell['height'] then
			height = spell['height']
		elseif E.global['nameplate']['spellListDefault']['height'] then
			height = E.global['nameplate']['spellListDefault']['height']
		end
		
		if width > height then
			local aspect = height / width
			frame.Icon:SetTexCoord(0.07, 0.93, (0.5 - (aspect/2))+0.07, (0.5 + (aspect/2))-0.07)
		elseif height > width then
			local aspect = width / height
			frame.Icon:SetTexCoord((0.5 - (aspect/2))+0.07, (0.5 + (aspect/2))-0.07, 0.07, 0.93)
		else
			frame.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end
		
		frame:SetWidth(width)
		frame:SetHeight(height)
		
		-- Stacks
		local textSize = 7
		
		if spell and spell['text'] then
			textSize = spell['text']
		elseif E.global['nameplate']['spellListDefault']['text'] then
			textSize = E.global['nameplate']['spellListDefault']['text']
		end
		
		frame.Stacks:FontTemplate(nil, textSize, 'OUTLINE')
		if stacks > 1 then
			frame.Stacks:SetText(stacks)
		else
			frame.Stacks:SetText("")
		end
		
		if duration > 0 and expiration then
			frame.TimeLeft:FontTemplate(nil, textSize, 'OUTLINE')
			frame.TimeLeft:Show()
			
			-- Expiration
			NP:UpdateAuraTime(frame, expiration, duration)
			frame:Show()
			NP.PolledHideIn(frame, expiration, duration)
		else
			frame:Show()
			frame.TimeLeft:Hide()
			NP.PolledHideIn(frame, -1, duration)
		end
	else 
		if UIFrameIsFlashing(frame) then
			UIFrameFlashStop(frame)
			frame:SetAlpha(1)
		end
		NP.PolledHideIn(frame, 0, duration)
	end
end

function NP:UpdateIconGrid(frame, guid)
	local widget = frame.AuraWidget
	local AuraIconFrames = widget.AuraIconFrames
	local AurasOnUnit = self:GetAuraList(guid)
	local AuraSlotIndex = 1
	local instanceid
	
	self.AuraCache = wipe(self.AuraCache)
	local auraCount = 0
	
	-- Cache displayable auras
	if AurasOnUnit then
		widget:Show()
		for instanceid in pairs(AurasOnUnit) do
			--for i,v in pairs(aura) do aura[i] = nil end
			local aura = {}
			aura.spellid, aura.expiration, aura.stacks, aura.caster, aura.duration, aura.texture, aura.type, aura.target = self:GetAuraInstance(guid, instanceid)
			if tonumber(aura.spellid) then
				aura.name = GetSpellInfo(tonumber(aura.spellid))
				if aura.type == -1 then
					aura.name = "School Lockout"
				end
				aura.unit = frame.unit
				
				-- Get Order/Priority
				if aura.expiration > GetTime() or aura.duration == 0 then
					auraCount = auraCount + 1
					self.AuraCache[auraCount] = aura
				end
			end
		end
	end
	
	sort(self.AuraCache, 
		function(a, b)
			if E.db.nameplate['sortDirection'] == 0 then
				return a.expiration < b.expiration 
			else
				return a.expiration > b.expiration 
			end
		end
	)
	
	-- Display Auras
	local rightWidth = 0
	local leftWidth = 0
	if auraCount > 0 then 
		for index = 1,  #self.AuraCache do
			local cachedaura = self.AuraCache[index]
			if cachedaura.spellid and cachedaura.expiration then 
				self:UpdateIcon(AuraIconFrames[AuraSlotIndex], cachedaura.texture, cachedaura.expiration, cachedaura.stacks, cachedaura.duration, cachedaura.name) 
				if index > 1 and mod(index,2) == 0 then
					rightWidth = rightWidth + AuraIconFrames[AuraSlotIndex]:GetWidth()
				elseif index > 1 and mod(index,2) ~= 0 then
					leftWidth = leftWidth + AuraIconFrames[AuraSlotIndex]:GetWidth()
				end
				AuraSlotIndex = AuraSlotIndex + 1
			end
			if AuraSlotIndex > NP.MAX_DISPLAYABLE_AURAS then break end
		end
	end
	
	if E.db.nameplate['auraAnchor'] and E.db.nameplate['auraAnchor'] == 2 then
		local offset = 0
		
		if rightWidth > leftWidth then
			offset = ( abs(rightWidth - leftWidth) / 2 ) * -1
		elseif leftWidth > rightWidth then
			offset = abs(leftWidth - rightWidth) / 2
		end
		
		AuraIconFrames[1]:SetPoint("BOTTOM", widget, offset, 3)
	end
	
	-- Clear Extra Slots
	for AuraSlotIndex = AuraSlotIndex, NP.MAX_DISPLAYABLE_AURAS do self:UpdateIcon(AuraIconFrames[AuraSlotIndex]) end
	
	self.AuraCache = wipe(self.AuraCache)
end

function NP:UpdateAuras(frame)
	-- Check for ID
	local guid = frame.guid
	
	if not guid then
		-- Attempt to ID widget via Name or Raid Icon
		if frame.hasClass then 
			guid = NP.ByName[frame.hp.name:GetText()]
		elseif frame.isMarked then 
			guid = NP.ByRaidIcon[frame.raidIconType] 
		end
		
		if guid then 
			frame.guid = guid
		else
			frame.AuraWidget:Hide()
			return
		end
	end
	
	self:UpdateIconGrid(frame, guid)
end

function NP:UpdateAurasByUnitID(unit)
	local unitType
	if UnitIsFriend("player", unit) then unitType = AURA_TARGET_FRIENDLY else unitType = AURA_TARGET_HOSTILE end	
	--if unitType == AURA_TARGET_FRIENDLY then return end		-- Filter
	
	-- Check the units auras
	local index
	local guid = UnitGUID(unit)
	-- Reset Auras for a guid
	self:WipeAuraList(guid)
	
	-- Debuffs
	for index = 1, 40 do
		local name , _, texture, count, dispelType, duration, expirationTime, unitCaster, _, _, spellid, _, isBossDebuff = UnitDebuff(unit, index)
		if not name then break end
		NP:SetSpellDuration(spellid, duration)			-- Caches the aura data for times when the duration cannot be determined (ie. via combat log)
		NP:SetAuraInstance(guid, spellid, expirationTime, count, UnitGUID(unitCaster or ""), duration, texture, AURA_TYPE[dispelType or "Debuff"], unitType, true)
	end	
	
	-- Buffs
	for index = 1, 40 do
		local name , _, texture, count, dispelType, duration, expirationTime, unitCaster, _, _, spellid, _, isBossDebuff = UnitBuff(unit, index)
		if not name then break end
		NP:SetSpellDuration(spellid, duration)			-- Caches the aura data for times when the duration cannot be determined (ie. via combat log)
		NP:SetAuraInstance(guid, spellid, expirationTime, count, UnitGUID(unitCaster or ""), duration, texture, AURA_TYPE[dispelType or "Buff"], unitType, true)
	end	
	
	if  NP.GUIDLockouts[guid] then
		for school,data in pairs(NP.GUIDLockouts[guid]) do
			if data.expire > GetTime() then
				NP:SetAuraInstance(data.dest, data.destSpell, data.expire, 1, data.source, data.dur, data.tex, -1, AURA_TARGET_HOSTILE, true)
			end
		end
	end

	local raidicon, name
	if UnitPlayerControlled(unit) then name = UnitName(unit) end
	raidicon = RaidIconIndex[GetRaidTargetIndex(unit) or ""]
	if raidicon then self.ByRaidIcon[raidicon] = guid end
	
	local frame = self:SearchForFrame(guid, raidicon, name)
	
	if frame then
		NP:UpdateAuras(frame)
	end
end

function NP:UpdateAurasByGUID(guid, name)
	if not GetPlayerInfoByGUID(guid) then return end
	local frame = self:SearchForFrame(guid, nil, name)
	
	if frame then
		frame.guid = guid
		NP:UpdateAuras(frame)
	end
end

function NP:UNIT_TARGET()
	self.TargetOfGroupMembers = wipe(self.TargetOfGroupMembers)
	
	for name, unitid in pairs(self.GroupMembers) do
		local targetOf = unitid..("target" or "")
		if UnitExists(targetOf) then
			self.TargetOfGroupMembers[UnitGUID(targetOf)] = targetOf
		end
	end
end

function NP:UNIT_AURA(event, unit)
	if unit == "target" then
		self:UpdateAurasByUnitID("target")
	elseif unit == "focus" then
		self:UpdateAurasByUnitID("focus")
	elseif UnitIsPlayer(unit) then
		self:UpdateAurasByUnitID(unit)
	end
end

function NP:StopCastAnimation(frame)
	frame.cb:Hide()	
	frame.cb:SetScript("OnUpdate", nil)
end

function NP:UpdateCastAnimation()
	local duration = GetTime() - self.startTime
	if duration > self.max then
		NP:StopCastAnimation(self:GetParent())
	else 
		self:SetValue(duration)
		self.time:SetFormattedText("%.1f ", (self.endTime - self.startTime) - duration)
	end
end

function NP:UpdateChannelAnimation()
	local duration = self.endTime - GetTime()
	if duration < 0 then
		NP:StopCastAnimation(self:GetParent())
	else 
		self:SetValue(duration) 
		self.time:SetFormattedText("%.1f ", duration)
	end
end

function NP:StartCastAnimationOnNameplate(frame, spellName, spellID, icon, startTime, endTime, notInterruptible, channel)
	if not (tonumber(GetCVar("showVKeyCastbar")) == 1) or not spellName then return; end
	local castbar = frame.cb

	castbar.name:SetText(spellName)
	castbar.icon:SetTexture(icon)
	castbar.endTime = endTime / 1e3
	castbar.startTime = startTime / 1e3
	castbar.max = (castbar.endTime - castbar.startTime)
	castbar:SetMinMaxValues(0, castbar.max)
	
	castbar:Show();
	
	if notInterruptible then 
		castbar.shield:Show()
		castbar:SetStatusBarColor(0.78, 0.25, 0.25, 1)
	else 
		castbar.shield:Hide()
		castbar:SetStatusBarColor(1, 208/255, 0)
	end
	
	if channel then 
		castbar:SetScript("OnUpdate", NP.UpdateChannelAnimation)	
	else 
		castbar:SetScript("OnUpdate", NP.UpdateCastAnimation)	
	end	
end


function NP:CastBar_OnShow(frame)
	frame:ClearAllPoints()
	frame:SetSize(frame:GetParent().hp:GetWidth(), self.db.cbheight)
	frame:SetPoint('TOP', frame:GetParent().hp, 'BOTTOM', 0, -8)
	frame:SetStatusBarTexture(E["media"].normTex)
	frame:GetStatusBarTexture():SetHorizTile(true)
	if(frame.shield:IsShown()) then
		frame:SetStatusBarColor(0.78, 0.25, 0.25, 1)
	else
		frame:SetStatusBarColor(1, 208/255, 0)
	end	
	
	self:SetVirtualBorder(frame, unpack(E["media"].bordercolor))
	self:SetVirtualBackdrop(frame, unpack(E["media"].backdropcolor))	
	
	frame.icon:Size(self.db.cbheight + frame:GetParent().hp:GetHeight() + 8)
	self:SetVirtualBorder(frame.icon, unpack(E["media"].bordercolor))
	self:SetVirtualBackdrop(frame.icon, unpack(E["media"].backdropcolor))		
end

function NP:CastBar_OnValueChanged(frame)
	local channel
	local spell, _, name, icon, start, finish, _, spellid, nonInt = UnitCastingInfo("target")
	
	if not spell then 
		spell, _, name, icon, start, finish, spellid, nonInt = UnitChannelInfo("target"); 
		channel = true 
	end	
	
	if spell then 
		NP:StartCastAnimationOnNameplate(frame:GetParent(), spell, spellid, icon, start, finish, nonInt, channel) 
	else 
		NP:StopCastAnimation(frame:GetParent()) 
	end
end

function NP:RemoveServerName(name)
	if name ~= nil then
		local loc = name:find("-")
		if loc then
			name = name:sub(0, loc - 1)
		end
	end
	return name
end
