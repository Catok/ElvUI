local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:NewModule('NamePlates', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

local OVERLAY = [=[Interface\TargetingFrame\UI-TargetingFrame-Flash]=]
local numChildren = -1
local backdrop
NP.Handled = {} --Skinned Nameplates
NP.BattleGroundHealers = {};

NP.factionOpposites = {
	['Horde'] = 1,
	['Alliance'] = 0,
}
NP.Healers = {
	[L['Restoration']] = true,
	[L['Holy']] = true,
	[L['Discipline']] = true,
}

function NP:Initialize()
	self.db = E.db["nameplate"]
	if E.private["nameplate"].enable ~= true then return end
	E.NamePlates = NP
	
	CreateFrame('Frame'):SetScript('OnUpdate', function(self, elapsed)
		if(WorldFrame:GetNumChildren() ~= numChildren) then
			numChildren = WorldFrame:GetNumChildren()
			NP:HookFrames(WorldFrame:GetChildren())
		end	
		
		NP:ForEachPlate(NP.CheckFilter)
		
		if(self.elapsed and self.elapsed > 0.2) then
			NP:ForEachPlate(NP.ScanHealth)
			NP:ForEachPlate(NP.CheckUnit_Guid)
			NP:ForEachPlate(NP.UpdateThreat)
			NP:ForEachPlate(NP.CheckRaidIcon)
			self.elapsed = 0
		else
			self.elapsed = (self.elapsed or 0) + elapsed
		end
	end)	
	
	if E.global['nameplate']['spellListDefault']['firstLoad'] then
		E.global["nameplate"]["spellList"] = deepcopy(E.global["nameplate"]["spellListDefault"]["defaultSpellList"])
		E.global['nameplate']['spellListDefault']['firstLoad'] = false
	end
	
	self:UpdateAllPlates()
end

function NP:QueueObject(frame, object)
	if not frame.queue then frame.queue = {} end
	frame.queue[object] = true
	
	if object.OldShow then
		object.Show = object.OldShow
		object:Show()
	end
	
	if object.OldTexture then
		object:SetTexture(object.OldTexture)
	end
end

function NP:CreateVirtualFrame(parent, point)
	if point == nil then point = parent end
	local noscalemult = E.mult * UIParent:GetScale()
	
	if point.backdrop then return end
	point.backdrop = parent:CreateTexture(nil, "BORDER")
	point.backdrop:SetDrawLayer("BORDER", -8)
	point.backdrop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*3, noscalemult*3)
	point.backdrop:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult*3, -noscalemult*3)
	point.backdrop:SetTexture(0, 0, 0, 1)

	point.backdrop2 = parent:CreateTexture(nil, "BORDER")
	point.backdrop2:SetDrawLayer("BORDER", -7)
	point.backdrop2:SetAllPoints(point)
	point.backdrop2:SetTexture(unpack(E["media"].backdropcolor))	
	
	point.bordertop = parent:CreateTexture(nil, "BORDER")
	point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
	point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
	point.bordertop:SetHeight(noscalemult)
	point.bordertop:SetTexture(unpack(E["media"].bordercolor))	
	point.bordertop:SetDrawLayer("BORDER", -7)
	
	point.borderbottom = parent:CreateTexture(nil, "BORDER")
	point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult*2, -noscalemult*2)
	point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult*2, -noscalemult*2)
	point.borderbottom:SetHeight(noscalemult)
	point.borderbottom:SetTexture(unpack(E["media"].bordercolor))	
	point.borderbottom:SetDrawLayer("BORDER", -7)
	
	point.borderleft = parent:CreateTexture(nil, "BORDER")
	point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
	point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult*2, -noscalemult*2)
	point.borderleft:SetWidth(noscalemult)
	point.borderleft:SetTexture(unpack(E["media"].bordercolor))	
	point.borderleft:SetDrawLayer("BORDER", -7)
	
	point.borderright = parent:CreateTexture(nil, "BORDER")
	point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
	point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult*2, -noscalemult*2)
	point.borderright:SetWidth(noscalemult)
	point.borderright:SetTexture(unpack(E["media"].bordercolor))	
	point.borderright:SetDrawLayer("BORDER", -7)	
end

function NP:SetVirtualBorder(parent, r, g, b)
	parent.bordertop:SetTexture(r, g, b)
	parent.borderbottom:SetTexture(r, g, b)
	parent.borderleft:SetTexture(r, g, b)
	parent.borderright:SetTexture(r, g, b)
end

function NP:SetVirtualBackdrop(parent, r, g, b)
	parent.backdrop2:SetTexture(r, g, b)
end

--Run a function for all visible nameplates, we use this for the filter, to check unitguid, and to hide drunken text
function NP:ForEachPlate(functionToRun, ...)
	for frame, _ in pairs(NP.Handled) do
		frame = _G[frame]
		if frame and frame:IsShown() then
			functionToRun(NP, frame, ...)
		end
	end
end

function NP:HideObjects(frame)
	for object in pairs(frame.queue) do
		object.OldShow = object.Show
		object.Show = E.noop
		
		if object:GetObjectType() == "Texture" then
			object.OldTexture = object:GetTexture()
			object:SetTexture(nil)
		end
		
		object:Hide()
	end
end

function NP:Colorize(frame)
	local r,g,b = frame.oldhp:GetStatusBarColor()
	for class, _ in pairs(RAID_CLASS_COLORS) do
		local r, g, b = floor(r*100+.5)/100, floor(g*100+.5)/100, floor(b*100+.5)/100
		if RAID_CLASS_COLORS[class].r == r and RAID_CLASS_COLORS[class].g == g and RAID_CLASS_COLORS[class].b == b then
			frame.hasClass = true
			frame.isFriendly = false
			frame.hp:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
			return
		end
	end
	
	frame.isPlayer = nil
	
	local color
	if g+b == 0 then -- hostile
		color = self.db.enemy
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = false
	elseif r+b == 0 then -- friendly npc
		color = self.db.friendlynpc
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = true
	elseif r+g > 1.95 then -- neutral
		color = self.db.neutral
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = false
	elseif r+g == 0 then -- friendly player
		color = self.db.friendlyplayer
		r,g,b = color.r, color.g, color.b
		frame.isFriendly = true
		frame.isPlayer = true
	else -- enemy player
		frame.isFriendly = false
		frame.isPlayer = true
	end
	frame.hasClass = false
	
	frame.hp:SetStatusBarColor(r,g,b)
end

function NP:HealthBar_OnShow(self, frame)
	if self.GetParent then frame = self; self = NP end
	frame = frame:GetParent()
	
	local noscalemult = E.mult * UIParent:GetScale()
	local r, g, b = frame.hp:GetStatusBarColor()
	--Have to reposition this here so it doesnt resize after being hidden
	frame.hp:ClearAllPoints()
	frame.hp:Size(self.db.width, self.db.height)	
	frame.hp:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 5)
	frame.hp:GetStatusBarTexture():SetHorizTile(true)

	self:HealthBar_ValueChanged(frame.oldhp)
	
	frame.hp.backdrop:SetPoint('TOPLEFT', -noscalemult*3, noscalemult*3)
	frame.hp.backdrop:SetPoint('BOTTOMRIGHT', noscalemult*3, -noscalemult*3)
	self:Colorize(frame)
	
	frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor = frame.hp:GetStatusBarColor()
	frame.hp.hpbg:SetTexture(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor, 0.25)
	
	--Position Overlay
	frame.overlay:ClearAllPoints()
	frame.overlay:SetAllPoints(frame.hp)
	
	--Set the name text
	frame.hp.name:SetText(frame.hp.oldname:GetText())	

	--Level Text
	if self.db.showlevel == true then
		local level, elite, mylevel = tonumber(frame.hp.oldlevel:GetText()), frame.hp.elite:IsShown(), UnitLevel("player")
		frame.hp.level:ClearAllPoints()
		if self.db.showhealth == true then
			frame.hp.level:SetPoint("RIGHT", frame.hp, "RIGHT", 2, 0)
		else
			frame.hp.level:SetPoint("RIGHT", frame.hp, "LEFT", -1, 0)
		end
		
		frame.hp.level:SetTextColor(frame.hp.oldlevel:GetTextColor())
		if frame.hp.boss:IsShown() then
			frame.hp.level:SetText("??")
			frame.hp.level:SetTextColor(0.8, 0.05, 0)
			frame.hp.level:Show()
		elseif not elite and level == mylevel then
			frame.hp.level:Hide()
		elseif level then
			frame.hp.level:SetText(level..(elite and "+" or ""))
			frame.hp.level:Show()
		end
	elseif frame.hp.level then
		frame.hp.level:Hide()
	end	
	
	self:HideObjects(frame)
end

function NP:HealthBar_ValueChanged(frame)
	local frame = frame:GetParent()
	frame.hp:SetMinMaxValues(frame.oldhp:GetMinMaxValues())
	frame.hp:SetValue(frame.oldhp:GetValue() - 1) --Blizzard bug fix
	frame.hp:SetValue(frame.oldhp:GetValue())
end

function NP:OnHide(frame)
	frame.hp:SetStatusBarColor(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor)
	frame.hp.name:SetTextColor(1, 1, 1)
	frame.overlay:Hide()
	frame.cb:Hide()
	frame.unit = nil
	frame.isMarked = nil
	frame.raidIconType = nil
	frame.threatStatus = nil
	frame.guid = nil
	frame.hasClass = nil
	frame.customColor = nil
	frame.customScale = nil
	frame.isFriendly = nil
	frame.hp.rcolor = nil
	frame.hp.gcolor = nil
	frame.hp.bcolor = nil
	frame.hp.shadow:SetAlpha(0)
	self:SetVirtualBackdrop(frame.hp, unpack(E["media"].backdropcolor))
	if frame.icons then
		for _,icon in ipairs(frame.icons) do
			icon:Hide()
		end
	end	
end

function NP:SkinPlate(frame)
	local oldhp, oldcb = frame:GetChildren()
	local threat, hpborder, overlay, oldname, oldlevel, bossicon, raidicon, elite = frame:GetRegions()
	local _, cbborder, cbshield, cbicon = oldcb:GetRegions()
	
	--Health Bar
	if not frame.hp then
		frame.oldhp = oldhp
		frame.hp = CreateFrame("Statusbar", nil, frame)
		frame.hp:SetFrameLevel(oldhp:GetFrameLevel())
		frame.hp:SetFrameStrata(oldhp:GetFrameStrata())
		frame.hp:CreateShadow('Default')
		frame.hp.shadow:ClearAllPoints()
		frame.hp.shadow:Point("TOPLEFT", frame.hp, -5, 5)
		frame.hp.shadow:Point("BOTTOMLEFT", frame.hp, -5, -5)
		frame.hp.shadow:Point("TOPRIGHT", frame.hp, 5, 5)
		frame.hp.shadow:Point("BOTTOMRIGHT", frame.hp, 5, -5)	
		frame.hp.shadow:SetBackdropBorderColor(1, 1, 1, 0.75)
		frame.hp.shadow:SetAlpha(0)
		self:CreateVirtualFrame(frame.hp)
		
		frame.hp.hpbg = frame.hp:CreateTexture(nil, 'BORDER')
		frame.hp.hpbg:SetAllPoints(frame.hp)
		frame.hp.hpbg:SetTexture(1,1,1,0.25) 				
	end
	frame.hp:SetStatusBarTexture(E["media"].npTex)
	self:SetVirtualBackdrop(frame.hp, unpack(E["media"].backdropcolor))
	
	--Level Text
	if not frame.hp.level then
		frame.hp.level = frame.hp:CreateFontString(nil, "OVERLAY")
		frame.hp.level:FontTemplate(nil, 10, 'OUTLINE')
		frame.hp.oldlevel = oldlevel
		frame.hp.boss = bossicon
		frame.hp.elite = elite
	end
	
	--Name Text
	if not frame.hp.name then
		frame.hp.name = frame.hp:CreateFontString(nil, 'OVERLAY')
		frame.hp.name:SetPoint('BOTTOMLEFT', frame.hp, 'TOPLEFT', -10, 3)
		frame.hp.name:SetPoint('BOTTOMRIGHT', frame.hp, 'TOPRIGHT', 10, 3)
		frame.hp.name:FontTemplate(nil, 10, 'OUTLINE')
		frame.hp.oldname = oldname
	end

	--Health Text
	if not frame.hp.value then
		frame.hp.value = frame.hp:CreateFontString(nil, "OVERLAY")	
		frame.hp.value:SetPoint("CENTER", frame.hp)
		frame.hp.value:FontTemplate(nil, 10, 'OUTLINE')
	end
	
	--Overlay
	overlay.oldTexture = overlay:GetTexture()
	overlay:SetTexture(1,1,1,0.15)
	frame.overlay = overlay
	
	--Cast Bar
	if not frame.cb then
		frame.oldcb = oldcb
		frame.cb = CreateFrame("Statusbar", nil, frame)
		frame.cb:SetFrameLevel(oldcb:GetFrameLevel())
		frame.cb:SetFrameStrata(oldcb:GetFrameStrata())
		self:CreateVirtualFrame(frame.cb)	
		frame.cb:Hide()
	end

	--Cast Time
	if not frame.cb.time then
		frame.cb.time = frame.cb:CreateFontString(nil, "ARTWORK")
		frame.cb.time:SetPoint("RIGHT", frame.cb, "LEFT", -1, 0)
		frame.cb.time:FontTemplate(nil, 10, 'OUTLINE')
	end
	
	--Cast Name
	if not frame.cb.name then
		frame.cb.name = frame.cb:CreateFontString(nil, "ARTWORK")
		frame.cb.name:SetPoint("TOP", frame.cb, "BOTTOM", 0, -3)
		frame.cb.name:FontTemplate(nil, 10, 'OUTLINE')
	end
	
	--Cast Icon
	if not frame.cb.icon then
		oldcb:SetAlpha(0)
		oldcb:SetScale(0.000001)
		cbicon:ClearAllPoints()
		cbicon:SetPoint("TOPLEFT", frame.hp, "TOPRIGHT", 8, 0)		
		cbicon:SetTexCoord(.07, .93, .07, .93)
		cbicon:SetDrawLayer("OVERLAY")
		cbicon:SetParent(frame.cb)
		frame.cb.icon = cbicon
		frame.cb.shield = cbshield
		self:CreateVirtualFrame(frame.cb, frame.cb.icon)
	end

	--Raid Icon
	if not frame.raidicon then
		raidicon:ClearAllPoints()
		raidicon:SetPoint("BOTTOM", frame.hp, "TOP", 0, 16)
		raidicon:SetSize(35, 35)
		raidicon:SetTexture([[Interface\AddOns\ElvUI\media\textures\raidicons.blp]])	
		frame.raidicon = raidicon	
	end
	
	--Heal Icon
	if not frame.healerIcon then
		frame.healerIcon = frame:CreateTexture(nil, 'ARTWORK')
		frame.healerIcon:SetPoint("BOTTOM", frame.hp, "TOP", 0, 16)
		frame.healerIcon:SetSize(35, 35)
		frame.healerIcon:SetTexture([[Interface\AddOns\ElvUI\media\textures\healer.tga]])	
	end
	
	if not frame.AuraWidget then
		--if not WatcherIsEnabled then Enable() end
		-- Create Base frame
		local f = CreateFrame("Frame", nil, frame)
		f:SetHeight(32); f:Show()
		f:SetPoint('BOTTOMRIGHT', frame.hp, 'TOPRIGHT', 0, 10)
		f:SetPoint('BOTTOMLEFT', frame.hp, 'TOPLEFT', 0, 10)
		
		-- Create Icon Array
		f.PollFunction = NP.UpdateAuraTime
		f.AuraIconFrames = {}
		local AuraIconFrames = f.AuraIconFrames
		
		if E.db.nameplate['maxAuras'] ~= nil then
			NP.MAX_DISPLAYABLE_AURAS = E.db.nameplate['maxAuras']
		end
		
		local anchorPoint = 1
		if E.db.nameplate['auraAnchor'] ~= nil then
			anchorPoint = E.db.nameplate['auraAnchor']
		end
		
		for index = 1, NP.MAX_DISPLAYABLE_AURAS do AuraIconFrames[index] = NP:CreateAuraIcon(f);  end
		
		-- Set Anchors
		if anchorPoint == 1 then
			AuraIconFrames[1]:SetPoint("BOTTOMRIGHT", f, 0, 3)
			for index = 2, NP.MAX_DISPLAYABLE_AURAS do AuraIconFrames[index]:SetPoint("BOTTOMRIGHT", AuraIconFrames[index-1], "BOTTOMLEFT", 0, 0) end
		elseif anchorPoint == 0 then
			AuraIconFrames[1]:SetPoint("BOTTOMLEFT", f, 0, 3)
			for index = 2, NP.MAX_DISPLAYABLE_AURAS do AuraIconFrames[index]:SetPoint("BOTTOMLEFT", AuraIconFrames[index-1], "BOTTOMRIGHT", 0, 0) end
		else
			AuraIconFrames[1]:SetPoint("BOTTOM", f, 0, 3)
			AuraIconFrames[2]:SetPoint("BOTTOMLEFT", AuraIconFrames[1], "BOTTOMRIGHT", 0, 0)
			for index = 3, NP.MAX_DISPLAYABLE_AURAS do 
				if mod(index, 2) == 0 then
					AuraIconFrames[index]:SetPoint("BOTTOMLEFT", AuraIconFrames[index-2], "BOTTOMRIGHT", 0, 0)
				else
					AuraIconFrames[index]:SetPoint("BOTTOMRIGHT", AuraIconFrames[index-2], "BOTTOMLEFT", 0, 0)
				end
			end
		end
		
		-- Functions
		f._Hide = f.Hide
		f.Hide = function() NP:ClearAuraContext(f); f:_Hide() end
		f:SetScript("OnHide", function() for index = 1, NP.MAX_DISPLAYABLE_AURAS do NP.PolledHideIn(AuraIconFrames[index], 0) end end)	
		f.Filter = DefaultFilterFunction
		f.UpdateContext = NP.UpdateAuraContext
		f.Update = NP.UpdateAuraContext
		f.UpdateTarget = NP.UpdateAuraTarget
		
		frame.AuraWidget = f
	end
		
	--Hide Old Stuff
	self:QueueObject(frame, oldhp)
	self:QueueObject(frame, oldlevel)
	self:QueueObject(frame, threat)
	self:QueueObject(frame, hpborder)
	self:QueueObject(frame, cbshield)
	self:QueueObject(frame, cbborder)
	self:QueueObject(frame, oldname)
	self:QueueObject(frame, bossicon)
	self:QueueObject(frame, elite)
	
	self:HealthBar_OnShow(frame.hp)
	self:CastBar_OnShow(frame.cb)
	if not self.hooks[frame] then
		self:HookScript(frame.cb, 'OnShow', 'CastBar_OnShow')
		self:HookScript(oldcb, 'OnValueChanged', 'CastBar_OnValueChanged')				
		self:HookScript(frame.hp, 'OnShow', 'HealthBar_OnShow')		
		self:HookScript(oldhp, 'OnValueChanged', 'HealthBar_ValueChanged')
		self:HookScript(frame, "OnHide", "OnHide")	
	end
	
	NP.Handled[frame:GetName()] = true
end

local good, bad, transition, transition2, combat, goodscale, badscale
function NP:UpdateThreat(frame)
	if frame.hasClass then return end
	combat = InCombatLockdown()
	good = self.db.goodcolor
	bad = self.db.badcolor
	goodscale = self.db.goodscale
	badscale = self.db.badscale
	transition = self.db.goodtransitioncolor
	transition2 = self.db.badtransitioncolor

	if self.db.enhancethreat ~= true then
		if(frame.region:IsShown()) then
			local _, val = frame.region:GetVertexColor()
			if(val > 0.7) then
				self:SetVirtualBorder(frame.hp, transition.r, transition.g, transition.b)
				if not frame.customScale and (goodscale ~= 1 or badscale ~= 1) then
					frame.hp:Height(self.db.height)
					frame.hp:Width(self.db.width)
				end					
			else
				self:SetVirtualBorder(frame.hp, bad.r, bad.g, bad.b)
				if not frame.customScale and badscale ~= 1 then
					frame.hp:Height(self.db.height * badscale)
					frame.hp:Width(self.db.width * badscale)
				end						
			end
		else
			self:SetVirtualBorder(frame.hp, unpack(E["media"].bordercolor))
			if not frame.customScale and goodscale ~= 1 then
				frame.hp:Height(self.db.height * goodscale)
				frame.hp:Width(self.db.width * goodscale)
			end								
		end
		frame.hp.name:SetTextColor(1, 1, 1)
	else
		if not frame.region:IsShown() then
			if combat and frame.isFriendly ~= true then
				--No Threat
				if E.role == "Tank" then
					if not frame.customColor then
						frame.hp:SetStatusBarColor(bad.r, bad.g, bad.b)
						frame.hp.hpbg:SetTexture(bad.r, bad.g, bad.b, 0.25)
					end

					if not frame.customScale and badscale ~= 1 then
						frame.hp:Height(self.db.height * badscale)
						frame.hp:Width(self.db.width * badscale)
					end								
					frame.threatStatus = "BAD"
				else
					if not frame.customColor then
						frame.hp:SetStatusBarColor(good.r, good.g, good.b)
						frame.hp.hpbg:SetTexture(good.r, good.g, good.b, 0.25)
					end
					
					if not frame.customScale and goodscale ~= 1 then
						frame.hp:Height(self.db.height * goodscale)
						frame.hp:Width(self.db.width * goodscale)
					end					
					frame.threatStatus = "GOOD"
				end		
			else
				--Set colors to their original, not in combat
				if not frame.customColor then
					frame.hp:SetStatusBarColor(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor)
					frame.hp.hpbg:SetTexture(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor, 0.25)
				end
				
				if not frame.customScale and (goodscale ~= 1 or badscale ~= 1) then
					frame.hp:Height(self.db.height)
					frame.hp:Width(self.db.width)
				end			
				frame.threatStatus = nil
			end
		else
			--Ok we either have threat or we're losing/gaining it
			local r, g, b = frame.region:GetVertexColor()
			if g + b == 0 then
				--Have Threat
				if E.role == "Tank" then
					if not frame.customColor then
						frame.hp:SetStatusBarColor(good.r, good.g, good.b)
						frame.hp.hpbg:SetTexture(good.r, good.g, good.b, 0.25)
					end
					
					if not frame.customScale and goodscale ~= 1 then
						frame.hp:Height(self.db.height * goodscale)
						frame.hp:Width(self.db.width * goodscale)
					end
					
					frame.threatStatus = "GOOD"
				else
					if not frame.customColor then
						frame.hp:SetStatusBarColor(bad.r, bad.g, bad.b)
						frame.hp.hpbg:SetTexture(bad.r, bad.g, bad.b, 0.25)
					end
					
					if not frame.customScale and badscale ~= 1 then
						frame.hp:Height(self.db.height * badscale)
						frame.hp:Width(self.db.width * badscale)
					end					
					frame.threatStatus = "BAD"
				end
			else
				--Losing/Gaining Threat
				
				if not frame.customScale and (goodscale ~= 1 or badscale ~= 1) then
					frame.hp:Height(self.db.height)
					frame.hp:Width(self.db.width)
				end	
				
				if E.role == "Tank" then
					if frame.threatStatus == "GOOD" then
						--Losing Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition2.r, transition2.g, transition2.b)	
							frame.hp.hpbg:SetTexture(transition2.r, transition2.g, transition2.b, 0.25)
						end
					else
						--Gaining Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition.r, transition.g, transition.b)	
							frame.hp.hpbg:SetTexture(transition.r, transition.g, transition.b, 0.25)
						end
					end
				else
					if frame.threatStatus == "GOOD" then
						--Losing Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition.r, transition.g, transition.b)	
							frame.hp.hpbg:SetTexture(transition.r, transition.g, transition.b, 0.25)
						end
					else
						--Gaining Threat
						if not frame.customColor then
							frame.hp:SetStatusBarColor(transition2.r, transition2.g, transition2.b)	
							frame.hp.hpbg:SetTexture(transition2.r, transition2.g, transition2.b, 0.25)
						end
					end				
				end
			end
		end
		
		if combat then
			frame.hp.name:SetTextColor(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor)
		else
			frame.hp.name:SetTextColor(1, 1, 1)
		end
	end
end

function NP:ScanHealth(frame)
	-- show current health value
	local minHealth, maxHealth = frame.oldhp:GetMinMaxValues()
	local valueHealth = frame.oldhp:GetValue()
	local d =(valueHealth/maxHealth)*100
	
	if self.db.showhealth == true then
		frame.hp.value:Show()
		frame.hp.value:SetText(E:ShortValue(valueHealth).." - "..(string.format("%d%%", math.floor((valueHealth/maxHealth)*100))))
	else
		frame.hp.value:Hide()
	end
			
	--Setup frame shadow to change depending on enemy players health, also setup targetted unit to have white shadow
	if frame.hasClass == true or frame.isFriendly == true then
		if(d <= 50 and d >= 20) then
			self:SetVirtualBorder(frame.hp, 1, 1, 0)
		elseif(d < 20) then
			self:SetVirtualBorder(frame.hp, 1, 0, 0)
		else
			self:SetVirtualBorder(frame.hp, unpack(E["media"].bordercolor))
		end
	elseif (frame.hasClass ~= true and frame.isFriendly ~= true) and self.db.enhancethreat == true then
		self:SetVirtualBorder(frame.hp, unpack(E["media"].bordercolor))
	end
end

--Scan all visible nameplate for a known unit.
function NP:CheckUnit_Guid(frame, ...)
	--local numParty, numRaid = GetNumPartyMembers(), GetNumRaidMembers()
	if UnitExists("target") and frame:GetAlpha() == 1 and UnitName("target") == frame.hp.name:GetText() then
		frame.guid = UnitGUID("target")
		frame.unit = "target"
		if UnitIsPlayer("target") and not NP.ByName[UnitName("target")] then
			NP.ByName[UnitName("target")] = UnitGUID("target")
		end
		NP:UpdateAurasByUnitID("target")
		frame.hp.shadow:SetAlpha(1)
	elseif frame.overlay:IsShown() and UnitExists("mouseover") and UnitName("mouseover") == frame.hp.name:GetText() then
		frame.guid = UnitGUID("mouseover")
		frame.unit = "mouseover"
		if UnitIsPlayer("mouseover") and not NP.ByName[UnitName("mouseover")] then
			NP.ByName[UnitName("mouseover")] = UnitGUID("mouseover")
		end
		NP:UpdateAurasByUnitID("mouseover")
		frame.hp.shadow:SetAlpha(0)
	elseif NP.ByName[frame.hp.name:GetText()] and frame.isPlayer then
		frame.guid = NP.ByName[frame.hp.name:GetText()]
		frame.unit = nil
		NP:UpdateAurasByGUID(frame.guid, frame.hp.name:GetText())
		frame.hp.shadow:SetAlpha(0)
	else
		frame.guid = nil
		frame.unit = nil
		frame.hp.shadow:SetAlpha(0)
	end	
end

function NP:TogglePlate(frame, hide)
	if hide == true then
		frame.hp:Hide()
		frame.cb:Hide()
		frame.overlay:Hide()
		frame.overlay:SetTexture(nil)
		frame.hp.oldlevel:Hide()	
	else
		frame.hp:Show()
		frame.overlay:SetTexture(1, 1, 1, 0.15)	
	end
end

--Create our blacklist for nameplates, so prevent a certain nameplate from ever showing
function NP:CheckFilter(frame, ...)
	local name = frame.hp.oldname:GetText()
	local db = E.global.nameplate["filter"][name]

	if db and db.enable then
		if db.hide then
			self:TogglePlate(frame, true)
		else
			self:TogglePlate(frame, false)
			
			if db.customColor then
				frame.customColor = db.customColor
				frame.hp.hpbg:SetTexture(db.color.r, db.color.g, db.color.b, 0.25)
				frame.hp:SetStatusBarColor(db.color.r, db.color.g, db.color.b)
			else
				frame.customColor = nil	
			end
			
			if db.customScale and db.customScale ~= 1 then
				frame.hp:Height(self.db.height * db.customScale)
				frame.hp:Width(self.db.width * db.customScale)
				frame.customScale = db.customScale
			else
				frame.customScale = nil
			end
		end
	else
		self:TogglePlate(frame, false)
	end
	
	--Check For Healers
	if self.BattleGroundHealers[name] then
		frame.healerIcon:Show()
	else
		frame.healerIcon:Hide()
	end
end

function NP:CheckHealers()
	for i = 1, GetNumBattlefieldScores() do
		local name, _, _, _, _, faction, _, _, _, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i);
		if name then
			name = name:match("(.+)%-.+") or name
			if name and self.Healers[talentSpec] and self.factionOpposites[self.PlayerFaction] == faction then
				self.BattleGroundHealers[name] = talentSpec
			elseif name and self.BattleGroundHealers[name] then
				self.BattleGroundHealers[name] = nil;
			end
		end
	end
end

function NP:PLAYER_ENTERING_WORLD()
	if InCombatLockdown() and self.db.combat then 
		SetCVar("nameplateShowEnemies", 1) 
	elseif self.db.combat then
		SetCVar("nameplateShowEnemies", 0) 
	end
	
	self:UpdateRoster()
	self:CleanAuraLists()
	
	table.wipe(self.BattleGroundHealers)
	local inInstance, instanceType = IsInInstance()
	if inInstance and instanceType == 'pvp' and self.db.markBGHealers then
		self.CheckHealerTimer = self:ScheduleRepeatingTimer("CheckHealers", 1)
		self:CheckHealers()
	else
		if self.CheckHealerTimer then
			self:CancelTimer(self.CheckHealerTimer)
			self.CheckHealerTimer = nil;
		end
	end
	
	self.PlayerFaction = UnitFactionGroup("player")
end

function NP:UpdateAllPlates()
	if E.private["nameplate"].enable ~= true then return end
	for frame, _ in pairs(self.Handled) do
		frame = _G[frame]
		self:SkinPlate(frame)
	end

	self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateRoster")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateRoster")
	self:RegisterEvent("PARTY_CONVERTED_TO_RAID", "UpdateRoster")
	self:RegisterEvent('UPDATE_MOUSEOVER_UNIT', 'UpdateCastInfo')
	self:RegisterEvent('PLAYER_TARGET_CHANGED', 'UpdateCastInfo')
	self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	self:RegisterEvent('UNIT_TARGET')
	self:RegisterEvent('UNIT_AURA')	
	self:PLAYER_ENTERING_WORLD()
end

function NP:ZONE_CHANGED_NEW_AREA()
	wipe(NP.ByName)
	wipe(NP.GUIDLockouts)
	wipe(NP.GUIDDR)
end

function NP:HookFrames(...)
	for index = 1, select('#', ...) do
		local frame = select(index, ...)
		local region = frame:GetRegions()
		
		if(not NP.Handled[frame:GetName()] and (frame:GetName() and frame:GetName():find("NamePlate%d")) and region and region:GetObjectType() == 'Texture' and region:GetTexture() == OVERLAY) then
			NP:SkinPlate(frame)
			frame.region = region
		end
	end
end

-- Taken from LibAuraInfo
NP.drSpells = {
	--[[ TAUNT ]]--
	-- Taunt (Warrior)
	[355] = "taunt",
	-- Taunt (Pet)
	[53477] = "taunt",
	-- Mocking Blow
	[694] = "taunt",
	-- Growl (Druid)
	[6795] = "taunt",
	-- Dark Command
	[56222] = "taunt",
	-- Hand of Reckoning
	[62124] = "taunt",
	-- Righteous Defense
	[31790] = "taunt",
	-- Distracting Shot
	[20736] = "taunt",
	-- Challenging Shout
	[1161] = "taunt",
	-- Challenging Roar
	[5209] = "taunt",
	-- Death Grip
	[49560] = "taunt",
	-- Challenging Howl
	[59671] = "taunt",
	-- Angered Earth
	[36213] = "taunt",
	
	--[[ DISORIENTS ]]--
	-- Dragon's Breath
	[31661] = "disorient",
	[33041] = "disorient",
	[33042] = "disorient",
	[33043] = "disorient",
	[42949] = "disorient",
	[42950] = "disorient",
	
	-- Hungering Cold
	[49203] = "disorient",
	
	-- Sap
	[6770] = "disorient",
	[2070] = "disorient",
	[11297] = "disorient",
	[51724] = "disorient",
	
	-- Gouge
	[1776] = "disorient",
		
	-- Hex (Guessing)
	[51514] = "disorient",
	
	-- Shackle
	[9484] = "disorient",
	[9485] = "disorient",
	[10955] = "disorient",
	
	-- Polymorph
	[118] = "disorient",
	[12824] = "disorient",
	[12825] = "disorient",
	[28272] = "disorient",
	[28271] = "disorient",
	[12826] = "disorient",
	[61305] = "disorient",
	[61025] = "disorient",
	[61721] = "disorient",
	[61780] = "disorient",
	
	-- Freezing Trap
	[3355] = "disorient",
	[14308] = "disorient",
	[14309] = "disorient",
	
	-- Freezing Arrow
	[60210] = "disorient",

	-- Wyvern Sting
	[19386] = "disorient",
	[24132] = "disorient",
	[24133] = "disorient",
	[27068] = "disorient",
	[49011] = "disorient",
	[49012] = "disorient",
	
	-- Repentance
	[20066] = "disorient",
		
	--[[ SILENCES ]]--
	-- Nether Shock
	[53588] = "silence",
	[53589] = "silence",
	
	-- Garrote
	[1330] = "silence",
	
	-- Arcane Torrent (Energy version)
	[25046] = "silence",
	
	-- Arcane Torrent (Mana version)
	[28730] = "silence",
	
	-- Arcane Torrent (Runic power version)
	[50613] = "silence",
	
	-- Silence
	[15487] = "silence",

	-- Silencing Shot
	[34490] = "silence",

	-- Improved Kick
	[18425] = "silence",

	-- Improved Counterspell
	[18469] = "silence",
	
	-- Spell Lock
	[19244] = "silence",
	[19647] = "silence",
	
	-- Shield of the Templar
	[63529] = "silence",
	
	-- Strangulate
	[47476] = "silence",
	[49913] = "silence",
	[49914] = "silence",
	[49915] = "silence",
	[49916] = "silence",
	
	-- Gag Order (Warrior talent)
	[18498] = "silence",
	
	--[[ DISARMS ]]--
	-- Snatch
	[53542] = "disarm",
	[53543] = "disarm",
	
	-- Dismantle
	[51722] = "disarm",
	
	-- Disarm
	[676] = "disarm",
	
	-- Chimera Shot - Scorpid
	[53359] = "disarm",
	
	-- Psychic Horror (Disarm effect)
	[64058] = "disarm",
	
	--[[ FEARS ]]--
	-- Blind
	[2094] = "fear",

	-- Fear (Warlock)
	[5782] = "fear",
	[6213] = "fear",
	[6215] = "fear",
	
	-- Seduction (Pet)
	[6358] = "fear",
	
	-- Howl of Terror
	[5484] = "fear",
	[17928] = "fear",

	-- Psychic scream
	[8122] = "fear",
	[8124] = "fear",
	[10888] = "fear",
	[10890] = "fear",
	
	-- Scare Beast
	[1513] = "fear",
	[14326] = "fear",
	[14327] = "fear",
	
	-- Turn Evil
	[10326] = "fear",
	
	-- Intimidating Shout
	[5246] = "fear",
	

	--[[ CONTROL STUNS ]]--
	-- Intercept (Felguard)
	[30153] = "ctrlstun",
	[30195] = "ctrlstun",
	[30197] = "ctrlstun",
	[47995] = "ctrlstun",
	
	-- Ravage
	[50518] = "ctrlstun",
	[53558] = "ctrlstun",
	[53559] = "ctrlstun",
	[53560] = "ctrlstun",
	[53561] = "ctrlstun",
	[53562] = "ctrlstun",
	
	-- Sonic Blast
	[50519] = "ctrlstun",
	[53564] = "ctrlstun",
	[53565] = "ctrlstun",
	[53566] = "ctrlstun",
	[53567] = "ctrlstun",
	[53568] = "ctrlstun",
	
	-- Concussion Blow
	[12809] = "ctrlstun",
	
	-- Shockwave
	[46968] = "ctrlstun",
	
	-- Hammer of Justice
	[853] = "ctrlstun",
	[5588] = "ctrlstun",
	[5589] = "ctrlstun",
	[10308] = "ctrlstun",

	-- Bash
	[5211] = "ctrlstun",
	[6798] = "ctrlstun",
	[8983] = "ctrlstun",
	
	--***********************************************************
	-- Intimidation
	[19577] = "ctrlstun",

	-- Maim
	[22570] = "ctrlstun",
	[49802] = "ctrlstun",

	-- Kidney Shot
	[408] = "ctrlstun",
	[8643] = "ctrlstun",

	-- War Stomp
	[20549] = "ctrlstun",

	-- Intercept
	[20252] = "ctrlstun",
	
	-- Deep Freeze
	[44572] = "ctrlstun",
			
	-- Shadowfury
	[30283] = "ctrlstun", 
	[30413] = "ctrlstun",
	[30414] = "ctrlstun",
	
	-- Holy Wrath
	[2812] = "ctrlstun",
	
	-- Inferno Effect
	[22703] = "ctrlstun",
	
	-- Demon Charge
	[60995] = "ctrlstun",
	
	-- Gnaw (Ghoul)
	[47481] = "ctrlstun",
	
	--[[ RANDOM STUNS ]]--
	-- Impact
	[12355] = "rndstun",

	-- Stoneclaw Stun
	[39796] = "rndstun",
	
	-- Seal of Justice
	[20170] = "rndstun",
	
	-- Revenge Stun
	[12798] = "rndstun",
	
	--[[ CYCLONE ]]--
	-- Cyclone
	[33786] = "cyclone",
	
	--[[ ROOTS ]]--
	-- Freeze (Water Elemental)
	[33395] = "ctrlroot",
	
	-- Pin (Crab)
	[50245] = "ctrlroot",
	[53544] = "ctrlroot",
	[53545] = "ctrlroot",
	[53546] = "ctrlroot",
	[53547] = "ctrlroot",
	[53548] = "ctrlroot",	
	
	-- Frost Nova
	[122] = "ctrlroot",
	[865] = "ctrlroot",
	[6131] = "ctrlroot",
	[10230] = "ctrlroot",
	[27088] = "ctrlroot",
	[42917] = "ctrlroot",
	
	-- Entangling Roots
	[339] = "ctrlroot",
	[1062] = "ctrlroot",
	[5195] = "ctrlroot",
	[5196] = "ctrlroot",
	[9852] = "ctrlroot",
	[9853] = "ctrlroot",
	[26989] = "ctrlroot",
	[53308] = "ctrlroot",
	
	-- Nature's Grasp (Uses different spellIDs than Entangling Roots for the same spell)
	[19970] = "ctrlroot",
	[19971] = "ctrlroot",
	[19972] = "ctrlroot",
	[19973] = "ctrlroot",
	[19974] = "ctrlroot",
	[19975] = "ctrlroot",
	[27010] = "ctrlroot",
	[53313] = "ctrlroot",
	
	-- Earthgrab (Storm, Earth and Fire talent)
	[8377] = "ctrlroot",
	[31983] = "ctrlroot",

	-- Web (Spider)
	[4167] = "ctrlroot",
	
	-- Venom Web Spray (Silithid)
	[54706] = "ctrlroot",
	[55505] = "ctrlroot",
	[55506] = "ctrlroot",
	[55507] = "ctrlroot",
	[55508] = "ctrlroot",
	[55509] = "ctrlroot",
	
	
	--[[ RANDOM ROOTS ]]--
	-- Improved Hamstring
	[23694] = "rndroot",
	
	-- Frostbite
	[12494] = "rndroot",

	-- Shattered Barrier
	[55080] = "rndroot",
	
	--[[ SLEEPS ]]--
	-- Hibernate
	[2637] = "sleep",
	[18657] = "sleep",
	[18658] = "sleep",
		
	--[[ HORROR ]]--
	-- Death Coil
	[6789] = "horror",
	[17925] = "horror",
	[17926] = "horror",
	[27223] = "horror",
	[47859] = "horror",
	[47860] = "horror",
	
	-- Psychic Horror
	[64044] = "horror",
	
	--[[ MISC ]]--
	-- Scatter Shot
	[19503] = "scatters",

	-- Cheap Shot
	[1833] = "cheapshot",

	-- Pounce
	[9005] = "cheapshot",
	[9823] = "cheapshot",
	[9827] = "cheapshot",
	[27006] = "cheapshot",
	[49803] = "cheapshot",

	-- Charge
	[7922] = "charge",
	
	-- Mind Control
	[605] = "mc",

	-- Banish
	[710] = "banish",
	[18647] = "banish",
	
	-- Entrapment
	[64804] = "entrapment",
	[64804] = "entrapment",
	[19185] = "entrapment",
}

NP.auraInfo = {
	[118]	= 50,	-- Polymorph
	[130]	= 30,	-- Slow Fall
	[131]	= 600,	-- Water Breathing
	[324]	= 600,	-- Lightning Shield
	[339]	= 30,	-- Entangling Roots
	[355]	= 3,	-- Taunt
	[498]	= 10,	-- Divine Protection
	[546]	= 600,	-- Water Walking
	[588]	= 1800,	-- Inner Fire
	[605]	= 60,	-- Mind Control
	[642]	= 8,	-- Divine Shield
	[673]	= 3600,	-- Lesser Armor
	[768]	= 0,	-- Cat Form
	[783]	= 0,	-- Travel Form
	[871]	= 12,	-- Shield Wall
	[982]	= 3,	-- Revive Pet
	[768]	= 0,	-- Cat Form
	[770]	= 300,	-- Faerie Fire
	[783]	= 0,	-- Travel Form
	[1038]	= 10,	-- Hand of Salvation
	[1044]	= 6,	-- Hand of Freedom
	[1066]	= 0,	-- Aquatic Form
	[1126]	= 3600,	-- Mark of the Wild
	[1161]	= 6,	-- Challenging Shout
	[1330]	= 3,	-- Garrote - Silence
	[1459]	= 3600,	-- Arcane Brilliance
	[1513]	= 20,	-- Scare Beast
	[1539]	= 10,	-- Feed Pet
	[1543]	= 0,	-- Flare
	[1604]	= 4,	-- Dazed
	[1706]	= 120,	-- Levitate
	[1715]	= 15,	-- Hamstring
	[1719]	= 12,	-- Recklessness
	[1776]	= 4,	-- Gouge
	[1784]	= 0,	-- Stealth
	[1833]	= 4,	-- Cheap Shot
	[1953]	= 1,	-- Blink
	[2094]	= 10,	-- Blind
	[2367]	= 3600,	-- Lesser Strength
	[2374]	= 3600,	-- Lesser Agility
	[2378]	= 3600,	-- Health
	[2479]	= 30,	-- Honorless Target
	[2565]	= 10,	-- Shield Block
	[2584]	= 0,	-- Waiting to Resurrect
	[2645]	= 0,	-- Ghost Wolf
	[2825]	= 40,	-- Bloodlust
	[2895]	= 0,	-- Wrath of Air Totem
	[3045]	= 15,	-- Rapid Fire
	[3166]	= 3600,	-- Lesser Intellect
	[3355]	= 20,	-- Freezing Trap
	[3409]	= 12,	-- Crippling Poison
	[3436]	= 300,	-- Wandering Plague
	[3600]	= 5,	-- Earthbind
	[3714]	= 600,	-- Path of Frost
	[4167]	= 5,	-- Web
	[2895]	= 0,	-- Wrath of Air Totem
	[3045]	= 15,	-- Rapid Fire
	[3166]	= 3600,	-- Lesser Intellect
	[3409]	= 12,	-- Crippling Poison
	[3436]	= 300,	-- Wandering Plague
	[3600]	= 5,	-- Earthbind
	[3714]	= 600,	-- Path of Frost
	[4167]	= 5,	-- Web
	[5116]	= 4,	-- Concussive Shot
	[5118]	= 0,	-- Aspect of the Cheetah
	[5209]	= 6,	-- Challenging Roar
	[5215]	= 0,	-- Prowl
	[5229]	= 10,	-- Enrage
	[5384]	= 360,	-- Feign Death
	[5484]	= 8,	-- Howl of Terror
	[5487]	= 0,	-- Bear Form
	[5697]	= 600,	-- Unending Breath
	[5760]	= 10,	-- Mind-numbing Poison
	[6150]	= 12,	-- Quick Shots
	[6196]	= 60,	-- Far Sight
	[6307]	= 0,	-- Blood Pact
	[6346]	= 180,	-- Fear Ward
	[6358]	= 30,	-- Seduction
	[6562]	= 0,	-- Heroic Presence
	[6653]	= 0,	-- Dire Wolf
	[6770]	= 60,	-- Sap
	[6788]	= 15,	-- Weakened Soul
	[6795]	= 3,	-- Growl
	[7178]	= 1800,	-- Water Breathing
	[7302]	= 1800,	-- Frost Armor
	[7321]	= 5,	-- Chilled
	[7353]	= 60,	-- Cozy Fire
	[7744]	= 0,	-- Will of the Forsaken
	[7870]	= 300,	-- Lesser Invisibility
	[7922]	= 1.5,	-- Charge Stun
	[8178]	= 0,	-- Grounding Totem Effect
	[8212]	= 1200,	-- Enlarge
	[8219]	= 3600,	-- Flip Out
	[8220]	= 3600,	-- Flip Out
	[8221]	= 3600,	-- Yaaarrrr
	[8222]	= 3600,	-- Yaaarrrr
	[8326]	= 0,	-- Ghost
	[8385]	= 3600,	-- Swift Wind
	[8395]	= 0,	-- Emerald Raptor
	[8515]	= 0,	-- Windfury Totem
	[8647]	= 10,	-- Expose Armor (1 combo point = 10 seconds)
	[9484]	= 50,	-- Shackle Undead
	[10060]	= 15,	-- Power Infusion
	[10326]	= 20,	-- Turn Evil
	[10796]	= 0,	-- Turquoise Raptor
	[10799]	= 0,	-- Violet Raptor
	[11196]	= 60,	-- Recently Bandaged
	[12042]	= 15,	-- Arcane Power
	[12043]	= 0,	-- Presence of Mind
	[12051]	= 6,	-- Evocation
	[12169]	= 5,	-- Shield Block
	[12323]	= 6,	-- Piercing Howl
	[12328]	= 10,	-- Sweeping Strikes
	[12472]	= 20,	-- Icy Veins
	[12536]	= 15,	-- Clearcasting
	[12544]	= 1800,	-- Frost Armor
	[12579]	= 15,	-- Winter's Chill
	[12654]	= 4,	-- Ignite
	[12721]	= 6,	-- Deep Wounds
	[12809]	= 5,	-- Concussion Blow
	[12976]	= 20,	-- Last Stand
	[13159]	= 0,	-- Aspect of the Pack
	[13165]	= 0,	-- Aspect of the Hawk
	[13443]	= 15,	-- Rend
	[13750]	= 15,	-- Adrenaline Rush
	[13810]	= 30,	-- Ice Trap
	[13877]	= 15,	-- Blade Flurry
	[14149]	= 20,	-- Remorseless
	[14177]	= 0,	-- Cold Blood
	[14267]	= 0,	-- Horde Flag
	[14268]	= 0,	-- Alliance Flag
	[14751]	= 30,	-- Chakra
	[14893]	= 15,	-- Inspiration
	[15007]	= 600,	-- Resurrection Sickness
	[15286]	= 1800,	-- Vampiric Embrace
	[15473]	= 0,	-- Shadowform
	[15487]	= 5,	-- Silence
	[15571]	= 4,	-- Dazed
	[15588]	= 10,	-- Thunderclap
	[15708]	= 5,	-- Mortal Strike
	[16166]	= 30,	-- Elemental Mastery
	[16188]	= 0,	-- Nature's Swiftness
	[16236]	= 15,	-- Ancestral Fortitude
	[16246]	= 15,	-- Clearcasting
	[16468]	= 0,	-- Mother's Milk
	[16491]	= 5,	-- Blood Craze
	[16509]	= 15,	-- Rend
	[16567]	= 600,	-- Tainted Mind
	[16591]	= 600,	-- Noggenfogger Elixir
	[16593]	= 15,	-- Noggenfogger Elixir
	[16595]	= 600,	-- Noggenfogger Elixir
	[16609]	= 3600,	-- Warchief's Blessing
	[16857]	= 600,	-- Faerie Fire (Feral)
	[16870]	= 8,	-- Clearcasting
	[16886]	= 15,	-- Nature's Grace
	[17116]	= 0,	-- Nature's Swiftness
	[17229]	= 0,	-- Winterspring Frostsaber
	[17364]	= 15,	-- Stormstrike
	[17465]	= 0,	-- Green Skeletal Warhorse
	[17481]	= 0,	-- Rivendare's Deathcharger
	[17539]	= 3600,	-- Greater Arcane Elixir
	[17619]	= 0,	-- Alchemist's Stone
	[17670]	= 0,	-- Argent Dawn Commission
	[17800]	= 30,	-- Shadow Mastery
	[17941]	= 10,	-- Shadow Trance
	[18118]	= 5,	-- Aftermath
	[18223]	= 30,	-- Curse of Exhaustion
	[18425]	= 1.5,	-- Silenced - Improved Kick
	[18469]	= 2,	-- Silenced - Improved Counterspell
	[18498]	= 3,	-- Silenced - Gag Order
	[18499]	= 10,	-- Berserker Rage
	[18708]	= 15,	-- Fel Domination
	[18990]	= 0,	-- Brown Kodo
	[19136]	= 5,	-- Stormbolt
	[19263]	= 5,	-- Deterrence
	[19503]	= 4,	-- Scatter Shot
	[19506]	= 0,	-- Trueshot Aura
	[19574]	= 10,	-- Bestial Wrath
	[19615]	= 10,	-- Frenzy Effect
	[19683]	= 900,	-- Tame Armored Scorpid
	[19746]	= 0,	-- Concentration Aura
	[19821]	= 5,	-- Arcane Bomb
	[20005]	= 5,	-- Chilled
	[20007]	= 15,	-- Holy Strength
	[20053]	= 15,	-- Conviction
	[20066]	= 60,	-- Repentance
	[20132]	= 10,	-- Redoubt
	[20164]	= 1800,	-- Seal of Justice
	[20165]	= 1800,	-- Seal of Insight
	[20170]	= 5,	-- Seal of Justice
	[20178]	= 8,	-- Reckoning
	[20217]	= 3600,	-- Blessing of Kings
	[20230]	= 12,	-- Retaliation
	[20253]	= 3,	-- Intercept
	[20511]	= 8,	-- Intimidating Shout
	[20549]	= 2,	-- War Stomp
	[20572]	= 15,	-- Blood Fury
	[20578]	= 10,	-- Cannibalize
	[20736]	= 6,	-- Distracting Shot
	[20911]	= 0,	-- Sanctuary
	[22717]	= 0,	-- Black War Steed
	[22718]	= 0,	-- Black War Kodo
	[22719]	= 0,	-- Black Battlestrider
	[22720]	= 0,	-- Black War Ram
	[22721]	= 0,	-- Black War Raptor
	[22722]	= 0,	-- Red Skeletal Warhorse
	[22723]	= 0,	-- Black War Tiger
	[22724]	= 0,	-- Black War Wolf
	[22812]	= 12,	-- Barkskin
	[22842]	= 20,	-- Frenzied Regeneration
	[22888]	= 7200,	-- Rallying Cry of the Dragonslayer
	[22911]	= 2,	-- Charge
	[22959]	= 30,	-- Critical Mass
	[23033]	= 0,	-- Battle Standard
	[23036]	= 0,	-- Battle Standard
	[23161]	= 0,	-- Dreadsteed
	[23214]	= 0,	-- Summon Charger
	[23219]	= 0,	-- Swift Mistsaber
	[23221]	= 0,	-- Swift Frostsaber
	[23227]	= 0,	-- Swift Palomino
	[23228]	= 0,	-- Swift White Steed
	[23229]	= 0,	-- Swift Brown Steed
	[23238]	= 0,	-- Swift Brown Ram
	[23239]	= 0,	-- Swift Gray Ram
	[23240]	= 0,	-- Swift White Ram
	[23241]	= 0,	-- Swift Blue Raptor
	[23242]	= 0,	-- Swift Olive Raptor
	[23243]	= 0,	-- Swift Orange Raptor
	[23246]	= 0,	-- Purple Skeletal Warhorse
	[23247]	= 0,	-- Great White Kodo
	[23248]	= 0,	-- Great Gray Kodo
	[23249]	= 0,	-- Great Brown Kodo
	[23250]	= 0,	-- Swift Brown Wolf
	[23251]	= 0,	-- Swift Timber Wolf
	[23252]	= 0,	-- Swift Gray Wolf
	[23333]	= 0,	-- Warsong Flag
	[23335]	= 0,	-- Silverwing Flag
	[23338]	= 0,	-- Swift Stormsaber
	[23451]	= 10,	-- Speed
	[23493]	= 10,	-- Restoration
	[23509]	= 0,	-- Frostwolf Howler
	[23510]	= 0,	-- Stormpike Battle Charger
	[23511]	= 30,	-- Demoralizing Shout
	[23693]	= 120,	-- Stormpike's Salvation
	[23694]	= 5,	-- Improved Hamstring
	[23885]	= 8,	-- Bloodthirst
	[23920]	= 5,	-- Spell Reflection
	[23978]	= 10,	-- Speed
	[24242]	= 0,	-- Swift Razzashi Raptor
	[24252]	= 0,	-- Swift Zulian Tiger
	[24259]	= 3,	-- Spell Lock
	[24378]	= 60,	-- Berserking
	[24450]	= 0,	-- Prowl
	[24529]	= 0,	-- Spirit Bond
	[24711]	= 3600,	-- Ninja Costume
	[24735]	= 3600,	-- Ghost Costume
	[24858]	= 0,	-- Moonkin Form
	[24907]	= 0,	-- Moonkin Aura
	[24932]	= 0,	-- Leader of the Pack
	[25046]	= 2,	-- Arcane Torrent
	[25163]	= 0,	-- Oozeling's Disgusting Aura
	[25228]	= 0,	-- Soul Link
	[25771]	= 120,	-- Forbearance
	[25780]	= 0,	-- Righteous Fury
	[25804]	= 900,	-- Rumsey Rum Black Label
	[25809]	= 12,	-- Crippling Poison
	[25810]	= 12,	-- Mind-numbing Poison
	[26004]	= 1800,	-- Mistletoe
	[26013]	= 900,	-- Deserter
	[26017]	= 30,	-- Vindication
	[26297]	= 10,	-- Berserking
	[27089]	= 30,	-- Drink
	[27813]	= 6,	-- Blessed Recovery
	[27818]	= 6,	-- Blessed Recovery
	[27827]	= 15,	-- Spirit of Redemption
	[28093]	= 15,	-- Lightning Speed
	[28176]	= 1800,	-- Fel Armor
	[28497]	= 3600,	-- Mighty Agility
	[28520]	= 3600,	-- Flask of Relentless Assault
	[28730]	= 2,	-- Arcane Torrent
	[28878]	= 0,	-- Heroic Presence
	[29131]	= 10,	-- Bloodrage
	[29166]	= 10,	-- Innervate
	[29178]	= 10,	-- Elemental Devastation
	[29348]	= 900,	-- Goldenmist Special Brew
	[29703]	= 6,	-- Dazed
	[29801]	= 0,	-- Rampage
	[29842]	= 10,	-- Second Wind
	[30070]	= 0,	-- Blood Frenzy
	[30802]	= 0,	-- Unleashed Rage
	[30823]	= 15,	-- Shamanistic Rage
	[31224]	= 5,	-- Cloak of Shadows
	[31579]	= 0,	-- Arcane Empowerment
	[31583]	= 0,	-- Arcane Empowerment
	[31589]	= 15,	-- Slow
	[31616]	= 10,	-- Nature's Guardian
	[31661]	= 5,	-- Dragon's Breath
	[31665]	= 0,	-- Master of Subtlety
	[31790]	= 3,	-- Righteous Defense
	[31801]	= 1800,	-- Seal of Truth
	[31803]	= 15,	-- Censure
	[31821]	= 6,	-- Aura Mastery
	[31842]	= 20,	-- Divine Favor
	[31884]	= 20,	-- Avenging Wrath
	[32182]	= 40,	-- Heroism
	[32223]	= 0,	-- Crusader Aura
	[32243]	= 0,	-- Tawny Wind Rider
	[32244]	= 0,	-- Blue Wind Rider
	[32245]	= 0,	-- Green Wind Rider
	[32246]	= 0,	-- Swift Red Wind Rider
	[32295]	= 0,	-- Swift Green Wind Rider
	[32297]	= 0,	-- Swift Purple Wind Rider
	[32388]	= 12,	-- Shadow Embrace
	[32600]	= 10,	-- Avoidance
	[32612]	= 20,	-- Invisibility
	[33197]	= 24,	-- Misery
	[33198]	= 24,	-- Misery
	[33206]	= 8,	-- Pain Suppression
	[33256]	= 1800,	-- Well Fed
	[33263]	= 1800,	-- Well Fed
	[33268]	= 1800,	-- Well Fed
	[33280]	= 3600,	-- Corporal
	[33395]	= 8,	-- Freeze
	[33660]	= 0,	-- Swift Pink Hawkstrider
	[33697]	= 15,	-- Blood Fury
	[33721]	= 3600,	-- Spellpower Elixir
	[33763]	= 10,	-- Lifebloom
	[33786]	= 6,	-- Cyclone
	[33891]	= 30,	-- Tree of Life
	[33943]	= 0,	-- Flight Form
	[34321]	= 10,	-- Call of the Nexus
	[34471]	= 10,	-- The Beast Within
	[34477]	= 20,	-- Misdirection
	[34490]	= 3,	-- Silencing Shot
	[34655]	= 8,	-- Deadly Poison
	[34767]	= 0,	-- Summon Charger
	[34769]	= 0,	-- Summon Warhorse
	[34790]	= 0,	-- Dark War Talbuk
	[34795]	= 0,	-- Red Hawkstrider
	[34837]	= 8,	-- Master Tactician
	[34896]	= 0,	-- Cobalt War Talbuk
	[34897]	= 0,	-- White War Talbuk
	[34898]	= 0,	-- Silver War Talbuk
	[34899]	= 0,	-- Tan War Talbuk
	[34936]	= 8,	-- Backlash
	[35020]	= 0,	-- Blue Hawkstrider
	[35025]	= 0,	-- Swift Green Hawkstrider
	[35027]	= 0,	-- Swift Purple Hawkstrider
	[35028]	= 0,	-- Swift Warstrider
	[35098]	= 20,	-- Rapid Killing
	[35099]	= 20,	-- Rapid Killing
	[35101]	= 4,	-- Concussive Barrage
	[35696]	= 0,	-- Demonic Knowledge
	[35706]	= 0,	-- Master Demonologist
	[35713]	= 0,	-- Great Blue Elekk
	[35714]	= 0,	-- Great Purple Elekk
	[36032]	= 6,	-- Arcane Blast
	[36444]	= 0,	-- Wintergrasp Water
	[36554]	= 3,	-- Shadowstep
	[36563]	= 10,	-- Shadowstep
	[37795]	= 3600,	-- Recruit
	[38384]	= 8,	-- Cone of Cold
	[39315]	= 0,	-- Cobalt Riding Talbuk
	[39316]	= 0,	-- Dark Riding Talbuk
	[39317]	= 0,	-- Silver Riding Talbuk
	[39319]	= 0,	-- White Riding Talbuk
	[39439]	= 10,	-- Aura of the Crusader
	[39627]	= 3600,	-- Elixir of Draenic Wisdom
	[39796]	= 3,	-- Stoneclaw Stun
	[39800]	= 0,	-- Red Riding Nether Ray
	[39802]	= 0,	-- Silver Riding Nether Ray
	[40120]	= 0,	-- Swift Flight Form
	[40623]	= 3600,	-- Apexis Vibrations
	[40625]	= 5400,	-- Apexis Emanations
	[41252]	= 0,	-- Raven Lord
	[41425]	= 30,	-- Hypothermia
	[41514]	= 0,	-- Azure Netherwing Drake
	[41516]	= 0,	-- Purple Netherwing Drake
	[42138]	= 7200,	-- Brewfest Enthusiast
	[42292]	= 0.1,	-- PvP Trinket
	[42650]	= 4,	-- Army of the Dead
	[43180]	= 30,	-- Food
	[43183]	= 30,	-- Drink
	[43196]	= 1800,	-- Armor
	[43265]	= 10,	-- Death and Decay
	[43680]	= 60,	-- Idle
	[43681]	= 60,	-- Inactive
	[43688]	= 0,	-- Amani War Bear
	[43751]	= 10,	-- Energized
	[43771]	= 3600,	-- Well Fed
	[43900]	= 0,	-- Swift Brewfest Ram
	[43927]	= 0,	-- Cenarion War Hippogryph
	[44151]	= 0,	-- Turbo-Charged Flying Machine
	[44153]	= 0,	-- Flying Machine
	[44413]	= 10,	-- Incanter's Absorption
	[44521]	= 0,	-- Preparation
	[44535]	= 6,	-- Spirit Heal
	[44572]	= 5,	-- Deep Freeze
	[44795]	= 0,	-- Parachute
	[45182]	= 3,	-- Cheating Death
	[45241]	= 8,	-- Focused Will
	[45242]	= 8,	-- Focused Will
	[45282]	= 8,	-- Natural Perfection
	[45283]	= 8,	-- Natural Perfection
	[45334]	= 4,	-- Feral Charge Effect
	[45373]	= 7200,	-- Bloodberry
	[45438]	= 10,	-- Ice Block
	[45472]	= 60,	-- Parachute
	[45524]	= 8,	-- Chains of Ice
	[45529]	= 20,	-- Blood Tap
	[45544]	= 8,	-- First Aid
	[45548]	= 30,	-- Food
	[46168]	= 0,	-- Pet Biscuit
	[46199]	= 0,	-- X-51 Nether-Rocket X-TREME
	[46356]	= 300,	-- Blood Elf Illusion
	[46604]	= 4,	-- Ice Block
	[46628]	= 0,	-- Swift White Hawkstrider
	[46833]	= 15,	-- Wrath of Elune
	[46857]	= 60,	-- Trauma
	[46916]	= 10,	-- Bloodsurge
	[46924]	= 6,	-- Bladestorm
	[46968]	= 4,	-- Shockwave
	[46987]	= 4,	-- Frostbolt
	[46989]	= 3,	-- Improved Blink
	[47241]	= 30,	-- Metamorphosis
	[47476]	= 5,	-- Strangulate
	[47481]	= 0,	-- Gnaw
	[47585]	= 6,	-- Dispersion
	[47753]	= 12,	-- Divine Aegis
	[47930]	= 15,	-- Grace
	[48018]	= 360,	-- Demonic Circle: Summon
	[48024]	= 0,	-- Headless Horseman's Mount
	[48027]	= 0,	-- Black War Elekk
	[48101]	= 1800,	-- Stamina
	[48111]	= 30,	-- Prayer of Mending
	[48263]	= 0,	-- Blood Presence
	[48265]	= 0,	-- Unholy Presence
	[48266]	= 0,	-- Frost Presence
	[48301]	= 10,	-- Mind Trauma
	[48391]	= 10,	-- Owlkin Frenzy
	[48418]	= 0,	-- Master Shapeshifter
	[48420]	= 0,	-- Master Shapeshifter
	[48421]	= 0,	-- Master Shapeshifter
	[48504]	= 15,	-- Living Seed
	[48517]	= 0,	-- Eclipse (Solar)
	[48518]	= 0,	-- Eclipse (Lunar)
	[48707]	= 5,	-- Anti-Magic Shell
	[48778]	= 0,	-- Acherus Deathcharger
	[48792]	= 12,	-- Icebound Fortitude
	[48836]	= 5,	-- Vengeful Justice
	[49016]	= 30,	-- Unholy Frenzy
	[49028]	= 12,	-- Dancing Rune Weapon
	[49039]	= 10,	-- Lichborne
	[49203]	= 0,	-- Hungering Cold
	[49206]	= 40,	-- Summon Gargoyle
	[49222]	= 300,	-- Bone Shield
	[49322]	= 0,	-- Swift Zhevra
	[49379]	= 0,	-- Great Brewfest Kodo
	[49560]	= 3,	-- Death Grip
	[49759]	= 30,	-- Teleport
	[50227]	= 5,	-- Sword and Board
	[50259]	= 3,	-- Dazed
	[50334]	= 15,	-- Berserk
	[50411]	= 3,	-- Dazed
	[50421]	= 20,	-- Scent of Blood
	[50461]	= 30,	-- Anti-Magic Zone
	[50518]	= 25,	-- Ravage
	[50519]	= 2,	-- Sonic Blast
	[50536]	= 10,	-- Unholy Blight
	[50589]	= 15,	-- Immolation Aura
	[50613]	= 2,	-- Arcane Torrent
	[50989]	= 3,	-- Flame Breath
	[51124]	= 10,	-- Killing Machine
	[51271]	= 20,	-- Pillar of Frost
	[51470]	= 0,	-- Elemental Oath
	[51514]	= 60,	-- Hex
	[51585]	= 8,	-- Blade Twisting
	[51690]	= 2,	-- Killing Spree
	[51693]	= 8,	-- Waylay
	[51713]	= 6,	-- Shadow Dance
	[51722]	= 10,	-- Dismantle
	[52127]	= 600,	-- Water Shield
	[52179]	= 0,	-- Astral Shift
	[52418]	= 0,	-- Carrying Seaforium
	[52437]	= 2,	-- Sudden Death
	[52459]	= 10,	-- End of Round
	[52610]	= 9,	-- Savage Roar
	[52910]	= 8,	-- Turn the Tables
	[53137]	= 0,	-- Abomination's Might
	[53138]	= 0,	-- Abomination's Might
	[53148]	= 1,	-- Charge
	[53220]	= 8,	-- Improved Steady Shot
	[53257]	= 15,	-- Cobra Strikes
	[53283]	= 30,	-- Food
	[53284]	= 1800,	-- Well Fed
	[53365]	= 15,	-- Unholy Strength
	[53390]	= 15,	-- Tidal Waves
	[53401]	= 20,	-- Rabid
	[53403]	= 20,	-- Rabid Power
	[53426]	= 5,	-- Lick Your Wounds
	[53434]	= 20,	-- Call of the Wild
	[53477]	= 3,	-- Taunt
	[53480]	= 12,	-- Roar of Sacrifice
	[53515]	= 8,	-- Owl's Focus
	[53517]	= 9,	-- Roar of Recovery
	[53563]	= 60,	-- Beacon of Light
	[53657]	= 60,	-- Judgements of the Pure
	[53746]	= 3600,	-- Wrath Elixir
	[53748]	= 3600,	-- Mighty Strength
	[53749]	= 3600,	-- Guru's Elixir
	[53751]	= 3600,	-- Elixir of Mighty Fortitude
	[53752]	= 3600,	-- Lesser Flask of Toughness
	[53755]	= 3600,	-- Flask of the Frost Wyrm
	[53758]	= 3600,	-- Flask of Stoneblood
	[53760]	= 3600,	-- Flask of Endless Rage
	[53768]	= 0,	-- Haunted
	[53806]	= 600,	-- Pygmy Oil
	[53817]	= 30,	-- Maelstrom Weapon
	[53908]	= 15,	-- Speed
	[54131]	= 5,	-- Bloodthirsty
	[54149]	= 15,	-- Infusion of Light
	[54212]	= 3600,	-- Flask of Pure Mojo
	[54277]	= 15,	-- Backdraft
	[54370]	= 12,	-- Nether Protection (Holy)
	[54371]	= 12,	-- Nether Protection (Fire)
	[54372]	= 12,	-- Nether Protection (Frost)
	[54373]	= 12,	-- Nether Protection (Arcane)
	[54374]	= 12,	-- Nether Protection (Shadow)
	[54375]	= 12,	-- Nether Protection (Nature)
	[54428]	= 15,	-- Divine Plea
	[54501]	= 6,	-- Consume Shadows
	[54508]	= 15,	-- Demonic Empowerment
	[54643]	= 20,	-- Teleport
	[54646]	= 1800,	-- Focus Magic
	[54648]	= 10,	-- Focus Magic
	[54726]	= 0,	-- Winged Steed of the Ebon Blade
	[54727]	= 0,	-- Winged Steed of the Ebon Blade
	[54753]	= 0,	-- White Polar Bear
	[54758]	= 12,	-- Hyperspeed Acceleration
	[54833]	= 10,	-- Innervate
	[54839]	= 10,	-- Purified Spirit
	[54861]	= 5,	-- Nitro Boosts
	[55001]	= 30,	-- Parachute
	[55018]	= 10,	-- Sonic Awareness
	[55021]	= 4,	-- Silenced - Improved Counterspell
	[55078]	= 21,	-- Blood Plague
	[55080]	= 3,	-- Shattered Barrier
	[55095]	= 21,	-- Frost Fever
	[55166]	= 20,	-- Tidal Force
	[55233]	= 10,	-- Vampiric Blood
	[55277]	= 15,	-- Stoneclaw Totem
	[55428]	= 20,	-- Lifeblood
	[55480]	= 20,	-- Lifeblood
	[55502]	= 20,	-- Lifeblood
	[55503]	= 20,	-- Lifeblood
	[55531]	= 0,	-- Mechano-hog
	[55610]	= 0,	-- Improved Icy Talons
	[55629]	= 3600,	-- First Lieutenant
	[55637]	= 15,	-- Lightweave
	[55694]	= 10,	-- Enraged Regeneration
	[55711]	= 480,	-- Weakened Heart
	[55741]	= 20,	-- Desecration
	[55817]	= 3600,	-- Eck Residue
	[56222]	= 3,	-- Dark Command
	[56453]	= 12,	-- Lock and Load
	[56520]	= 1800,	-- Blessing of Might
	[56654]	= 6,	-- Rapid Recuperation
	[57073]	= 30,	-- Drink
	[57100]	= 3600,	-- Well Fed
	[57102]	= 3600,	-- Well Fed
	[57111]	= 3600,	-- Well Fed
	[57286]	= 3600,	-- Well Fed
	[57288]	= 3600,	-- Well Fed
	[57291]	= 3600,	-- Well Fed
	[57294]	= 3600,	-- Well Fed
	[57325]	= 3600,	-- Well Fed
	[57327]	= 3600,	-- Well Fed
	[57329]	= 3600,	-- Well Fed
	[57330]	= 120,	-- Horn of Winter
	[57332]	= 3600,	-- Well Fed
	[57334]	= 3600,	-- Well Fed
	[57348]	= 0,	-- Carrying an RP-GG
	[57350]	= 6,	-- Illusionary Barrier
	[57356]	= 3600,	-- Well Fed
	[57358]	= 3600,	-- Well Fed
	[57365]	= 3600,	-- Well Fed
	[57367]	= 3600,	-- Well Fed
	[57371]	= 3600,	-- Well Fed
	[57399]	= 3600,	-- Well Fed
	[57516]	= 12,	-- Enrage
	[57524]	= 120,	-- Metanoia
	[57531]	= 0,	-- Arcane Potency
	[57669]	= 15,	-- Replenishment
	[57723]	= 600,	-- Exhaustion
	[57724]	= 600,	-- Sated
	[57761]	= 15,	-- Brain Freeze
	[57819]	= 0,	-- Argent Champion
	[57820]	= 0,	-- Ebon Champion
	[57821]	= 0,	-- Champion of the Kirin Tor
	[57822]	= 0,	-- Wyrmrest Champion
	[57933]	= 6,	-- Tricks of the Trade
	[57934]	= 20,	-- Tricks of the Trade
	[57940]	= 0,	-- Essence of Wintergrasp
	[58045]	= 0,	-- Essence of Wintergrasp
	[58179]	= 12,	-- Infected Wounds
	[58371]	= 180,	-- Recently Slain
	[58374]	= 10,	-- Glyph of Shield Block
	[58427]	= 0,	-- Overkill
	[58449]	= 1800,	-- Strength
	[58450]	= 1800,	-- Agility
	[58499]	= 7200,	-- Happy
	[58500]	= 7200,	-- Angry
	[58511]	= 45,	-- Rotten Apple Aroma
	[58514]	= 45,	-- Rotten Banana Aroma
	[58519]	= 45,	-- Spit
	[58549]	= 1800,	-- Tenacity
	[58555]	= 180,	-- Great Honor
	[58556]	= 180,	-- Greater Honor
	[58557]	= 180,	-- Greatest Honor
	[58567]	= 30,	-- Sunder Armor
	[58600]	= 10,	-- Restricted Flight Area
	[58617]	= 10,	-- Glyph of Heart Strike
	[58683]	= 0,	-- Savage Combat
	[58729]	= 0,	-- Spiritual Immunity
	[58861]	= 2,	-- Bash
	[58875]	= 15,	-- Spirit Walk
	[58882]	= 6,	-- Rapid Recuperation
	[59052]	= 15,	-- Freezing Fog
	[59542]	= 15,	-- Gift of the Naaru
	[59547]	= 15,	-- Gift of the Naaru
	[59548]	= 15,	-- Gift of the Naaru
	[59568]	= 0,	-- Blue Drake
	[59569]	= 0,	-- Bronze Drake
	[59570]	= 0,	-- Red Drake
	[59578]	= 15,	-- The Art of War
	[59620]	= 15,	-- Berserk
	[59626]	= 10,	-- Black Magic
	[59628]	= 6,	-- Tricks of the Trade
	[59638]	= 4,	-- Frostbolt
	[59725]	= 5,	-- Spell Reflection
	[59752]	= 0.1,	-- Every Man for Himself
	[59785]	= 0,	-- Black War Mammoth
	[59788]	= 0,	-- Black War Mammoth
	[59793]	= 0,	-- Wooly Mammoth
	[59797]	= 0,	-- Ice Mammoth
	[59889]	= 6,	-- Borrowed Time
	[59911]	= 1800,	-- Tenacity
	[59961]	= 0,	-- Red Proto-Drake
	[59996]	= 0,	-- Blue Proto-Drake
	[60002]	= 0,	-- Time-Lost Proto-Drake
	[60024]	= 0,	-- Violet Proto-Drake
	[60025]	= 0,	-- Albino Drake
	[60062]	= 10,	-- Essence of Life
	[60064]	= 10,	-- Now is the time!
	[60065]	= 10,	-- Reflection of Torment
	[60097]	= 10,	-- Feeding Frenzy
	[60114]	= 0,	-- Armored Brown Bear
	[60116]	= 0,	-- Armored Brown Bear
	[60118]	= 0,	-- Black War Bear
	[60119]	= 0,	-- Black War Bear
	[60196]	= 12,	-- Berserker!
	[60214]	= 20,	-- Seal of the Pantheon
	[60215]	= 40,	-- Lavanthor's Talisman
	[60218]	= 10,	-- Essence of Gossamer
	[60229]	= 15,	-- Greatness
	[60233]	= 15,	-- Greatness
	[60234]	= 15,	-- Greatness
	[60302]	= 10,	-- Meteorite Whetstone
	[60305]	= 20,	-- Heart of a Dragon
	[60314]	= 10,	-- Fury of the Five Flights
	[60318]	= 13,	-- Edward's Insight
	[60340]	= 3600,	-- Accuracy
	[60341]	= 3600,	-- Deadly Strikes
	[60345]	= 3600,	-- Armor Piercing
	[60346]	= 3600,	-- Lightning Speed
	[60347]	= 3600,	-- Mighty Thoughts
	[60424]	= 0,	-- Mekgineer's Chopper
	[60433]	= 12,	-- Earth and Moon
	[60437]	= 10,	-- Grim Toll
	[60479]	= 10,	-- Forge Ember
	[60503]	= 9,	-- Taste for Blood
	[60512]	= 15,	-- Healing Trance
	[60520]	= 15,	-- Spark of Life
	[60525]	= 10,	-- Majestic Dragon Figurine
	[60549]	= 10,	-- Deadly Aggression
	[60551]	= 10,	-- Furious Gladiator's Libram of Fortitude
	[60553]	= 10,	-- Relentless Aggression
	[60568]	= 10,	-- Furious Gladiator's Idol of Steadfastness
	[60946]	= 5,	-- Nightmare
	[60947]	= 5,	-- Nightmare
	[60956]	= 0,	-- Improved Health Funnel
	[61258]	= 5,	-- Runic Return
	[61294]	= 0,	-- Green Proto-Drake
	[61309]	= 0,	-- Magnificent Flying Carpet
	[61316]	= 3600,	-- Dalaran Brilliance
	[61336]	= 12,	-- Survival Instincts
	[61394]	= 4,	-- Frozen Wake
	[61427]	= 20,	-- Infinite Speed
	[61447]	= 0,	-- Traveler's Tundra Mammoth
	[61465]	= 0,	-- Grand Black War Mammoth
	[61467]	= 0,	-- Grand Black War Mammoth
	[61469]	= 0,	-- Grand Ice Mammoth
	[61485]	= 60,	-- Dreadful Roar
	[61573]	= 0,	-- Banner of the Alliance
	[61619]	= 10,	-- Tentacles
	[61671]	= 10,	-- Crusader's Glory
	[61684]	= 16,	-- Dash
	[61685]	= 4,	-- Charge
	[61721]	= 50,	-- Polymorph
	[61858]	= 9,	-- Plague Slime
	[62064]	= 1800,	-- Tower Control
	[62124]	= 3,	-- Hand of Reckoning
	[62408]	= 300,	-- Ethereal Oil
	[62552]	= 60,	-- Defend
	[62574]	= 0,	-- Warts-B-Gone Lip Balm
	[62606]	= 10,	-- Savage Defense
	[63167]	= 10,	-- Decimation
	[63232]	= 0,	-- Stormwind Steed
	[63283]	= 300,	-- Totem of Wrath
	[63433]	= 0,	-- Orgrimmar Champion's Pennant
	[63468]	= 8,	-- Piercing Shots
	[63500]	= 0,	-- Argent Crusade Valiant's Pennant
	[63529]	= 10,	-- Dazed - Avenger's Shield
	[63619]	= 5,	-- Shadowcrawl
	[63635]	= 0,	-- Darkspear Raptor
	[63640]	= 0,	-- Orgrimmar Wolf
	[63641]	= 0,	-- Thunder Bluff Kodo
	[63665]	= 2.5,	-- Charge
	[63672]	= 15,	-- ObsoleteBlack Arrow
	[63685]	= 5,	-- Freeze
	[63729]	= 3600,	-- Elixir of Minor Accuracy
	[63844]	= 0,	-- Argent Hippogryph
	[63963]	= 0,	-- Rusted Proto-Drake
	[64044]	= 3,	-- Psychic Horror
	[64058]	= 10,	-- Psychic Horror
	[64205]	= 10,	-- Divine Sacrifice
	[64368]	= 10,	-- Eradication
	[64370]	= 10,	-- Eradication
	[64371]	= 10,	-- Eradication
	[64373]	= 0,	-- Armistice
	[64419]	= 15,	-- Sniper Training
	[64420]	= 15,	-- Sniper Training
	[64440]	= 10,	-- Blade Warding
	[64524]	= 20,	-- Platinum Disks of Battle
	[64568]	= 20,	-- Blood Reserve
	[64658]	= 0,	-- Black Wolf
	[64659]	= 0,	-- Venomhide Ravasaur
	[64695]	= 5,	-- Earthgrab
	[64701]	= 15,	-- Elemental Mastery
	[64810]	= 300,	-- Bested Ironforge
	[64844]	= 8,	-- Divine Hymn
	[64855]	= 10,	-- Blade Barrier
	[64856]	= 10,	-- Blade Barrier
	[64951]	= 12,	-- Primal Wrath
	[64977]	= 0,	-- Black Skeletal Horse
	[65019]	= 10,	-- Mjolnir Runestone
	[65156]	= 10,	-- Juggernaut
	[65247]	= 3600,	-- Well Fed
	[65264]	= 6,	-- Lava Flows
	[65639]	= 0,	-- Swift Red Hawkstrider
	[65641]	= 0,	-- Great Golden Kodo
	[65642]	= 0,	-- Turbostrider
	[65644]	= 0,	-- Swift Purple Raptor
	[65645]	= 0,	-- White Skeletal Warhorse
	[65646]	= 0,	-- Swift Burgundy Wolf
	[65745]	= 300,	-- Path of Cenarius
	[66090]	= 0,	-- Quel'dorei Steed
	[66091]	= 0,	-- Sunreaver Hawkstrider
	[66122]	= 0,	-- Magic Rooster
	[66157]	= 0,	-- Honorable Defender
	[66803]	= 20,	-- Desolation
	[66846]	= 0,	-- Ochre Skeletal Warhorse
	[66906]	= 0,	-- Argent Charger
	[67016]	= 3600,	-- Flask of the North
	[67017]	= 3600,	-- Flask of the North
	[67018]	= 3600,	-- Flask of the North
	[67117]	= 15,	-- Unholy Might
	[67354]	= 9,	-- Evasion
	[67355]	= 16,	-- Agile
	[67358]	= 9,	-- Rejuvenating
	[67360]	= 12,	-- Blessing of the Moon Goddess
	[67364]	= 15,	-- Holy Judgement
	[67371]	= 16,	-- Holy Strength
	[67378]	= 18,	-- Evasion
	[67383]	= 20,	-- Unholy Force
	[67388]	= 15,	-- Spiritual Trance
	[67391]	= 18,	-- Volcanic Fury
	[67466]	= 0,	-- Argent Warhorse
	[67596]	= 15,	-- Tremendous Fortitude
	[67631]	= 10,	-- Aegis
	[67669]	= 10,	-- Elusive Power
	[67671]	= 10,	-- Fury
	[67683]	= 20,	-- Celerity
	[67684]	= 20,	-- Hospitality
	[67694]	= 20,	-- Defensive Tactics
	[67695]	= 20,	-- Rage
	[67696]	= 10,	-- Energized
	[67703]	= 15,	-- Paragon
	[67708]	= 15,	-- Paragon
	[67713]	= 0,	-- Mote of Flame
	[67737]	= 0,	-- Risen Fury
	[67738]	= 20,	-- Rising Fury
	[67890]	= 3,	-- Cobalt Frag Bomb
	[68054]	= 600,	-- Pressing Engagement
	[68055]	= 20,	-- Judgements of the Just
	[68056]	= 0,	-- Swift Horde Wolf
	[68057]	= 0,	-- Swift Alliance Steed
	[68269]	= 0,	-- The Brewmaiden's Blessing
	[68766]	= 20,	-- Desecration
	[69369]	= 8,	-- Predator's Swiftness
	[70013]	= 0,	-- Quel'Delar's Compulsion
	[70029]	= 0.1,	-- The Beast Within
	[70657]	= 15,	-- Advantage
	[70691]	= 15,	-- Rejuvenation
	[70721]	= 6,	-- Omen of Doom
	[70725]	= 10,	-- Enraged Defense
	[70728]	= 10,	-- Exploit Weakness
	[70753]	= 5,	-- Pushing the Limit
	[70757]	= 10,	-- Holiness
	[70806]	= 10,	-- Rapid Currents
	[70840]	= 10,	-- Devious Minds
	[70855]	= 10,	-- Blood Drinker
	[70893]	= 10,	-- Culling the Herd
	[70940]	= 6,	-- Divine Guardian
	[23223]	= 0,	-- Swift White Mechanostrider
	[41513]	= 0,	-- Onyx Netherwing Drake
	[53805]	= 600,	-- Pygmy Oil
	[71007]	= 10,	-- Stinger
	[71041]	= 1800,	-- Dungeon Deserter
	[71165]	= 15,	-- Molten Core
	[71177]	= 15,	-- Vicious
	[71184]	= 15,	-- Soothing
	[71187]	= 15,	-- Formidable
	[71192]	= 15,	-- Blessed
	[71197]	= 15,	-- Evasive
	[71199]	= 30,	-- Furious
	[71216]	= 15,	-- Enraged
	[71220]	= 15,	-- Energized
	[71227]	= 15,	-- Indomitable
	[71396]	= 10,	-- Rage of the Fallen
	[71401]	= 15,	-- Icy Rage
	[71403]	= 10,	-- Fatal Flaws
	[71432]	= 0,	-- Mote of Anger
	[71484]	= 30,	-- Strength of the Taunka
	[71486]	= 30,	-- Power of the Taunka
	[71491]	= 30,	-- Aim of the Iron Dwarves
	[71492]	= 30,	-- Speed of the Vrykul
	[71564]	= 20,	-- Deadly Precision
	[71570]	= 10,	-- Cultivated Power
	[71572]	= 10,	-- Cultivated Power
	[71584]	= 15,	-- Revitalized
	[71586]	= 10,	-- Hardened Skin
	[71600]	= 20,	-- Surging Power
	[71601]	= 20,	-- Surge of Power
	[71633]	= 10,	-- Thick Skin
	[71824]	= 6,	-- Lava Burst
	[71864]	= 6,	-- Fountain of Light
	[71882]	= 10,	-- Invigoration
	[72412]	= 10,	-- Frostforged Champion
	[72414]	= 10,	-- Frostforged Defender
	[72416]	= 10,	-- Frostforged Sage
	[72418]	= 10,	-- Chilling Knowledge
	[72586]	= 1800,	-- Blessing of Forgotten Kings
	[72590]	= 3600,	-- Fortitude
	[72808]	= 0,	-- Bloodbathed Frostbrood Vanquisher
	[72968]	= 0,	-- Precious's Ribbon
	[73313]	= 0,	-- Crimson Deathcharger
	[74347]	= 3,	-- Silenced - Gag Order
	[75447]	= 0,	-- Ferocious Inspiration
	[75596]	= 0,	-- Frosty Flying Carpet
	[75617]	= 0,	-- Celestial Steed
	[75618]	= 0,	-- Celestial Steed
	[75619]	= 0,	-- Celestial Steed
	[75620]	= 0,	-- Celestial Steed
	[75957]	= 0,	-- X-53 Touring Rocket
	[75972]	= 0,	-- X-53 Touring Rocket
	[5784]	= 0,	-- Felsteed
	[8733]	= 3600,	-- Blessing of Blackfathom
	[19740]	= 3600,	-- Blessing of Might
	[25040]	= 900,	-- Mark of Nature
	[27683]	= 3600,	-- Shadow Protection
	[32386]	= 12,	-- Shadow Embrace
	[35018]	= 0,	-- Purple Hawkstrider
	[35022]	= 0,	-- Black Hawkstrider
	[45123]	= 0,	-- Romantic Picnic
	[46202]	= 10,	-- Pierce Armor
	[51987]	= 20,	-- Arcane Infusion
	[53747]	= 3600,	-- Elixir of Spirit
	[54452]	= 3600,	-- Adept's Elixir
	[54842]	= 0,	-- Thunder Charge
	[57107]	= 3600,	-- Well Fed
	[58269]	= 0,	-- Iceskin Stoneform
	[58501]	= 600,	-- Iron Boot Flask
	[60494]	= 10,	-- Dying Curse
	[60569]	= 10,	-- Relentless Survival
	[62061]	= 3600,	-- Festive Holiday Mount
	[64657]	= 0,	-- White Kodo
	[64731]	= 0,	-- Sea Turtle
	[65006]	= 10,	-- Eye of the Broodmother
	[66088]	= 0,	-- Sunreaver Dragonhawk
	[3593]	= 3600,	-- Elixir of Fortitude
	[8272]	= 600,	-- Mind Tremor
	[11396]	= 3600,	-- Greater Intellect
	[11841]	= 600,	-- Static Barrier
	[21562]	= 3600,	-- Power Word: Fortitude
	[23844]	= 0,	-- Master Demonologist
	[32752]	= 5,	-- Summoning Disorientation
	[33257]	= 1800,	-- Well Fed
	[50434]	= 10,	-- Chilblains
	[50720]	= 1800,	-- Vigilance
	[57360]	= 3600,	-- Well Fed
	[58479]	= 3600,	-- Nearly Well Fed
	[58999]	= 0,	-- Big Blizzard Bear
	[59658]	= 15,	-- Argent Heroism
	[60106]	= 300,	-- Old Spices
	[60122]	= 30,	-- Baby Spice
	[60530]	= 12,	-- Forethought Talisman
	[2974]	= 10,	-- Wing Clip
	[6117]	= 1800,	-- Mage Armor
	[10668]	= 3600,	-- Spirit of Boar
	[11334]	= 3600,	-- Greater Agility
	[15357]	= 15,	-- Inspiration
	[16511]	= 60,	-- Hemorrhage
	[16711]	= 300,	-- Grow
	[17463]	= 0,	-- Blue Skeletal Horse
	[28491]	= 3600,	-- Healing Power
	[30808]	= 0,	-- Unleashed Rage
	[44212]	= 3600,	-- Jack-o'-Lanterned!
	[48846]	= 20,	-- Runic Infusion
	[54424]	= 0,	-- Fel Intelligence
	[58180]	= 12,	-- Infected Wounds
	[65640]	= 0,	-- Swift Gray Steed
	[68188]	= 0,	-- Crusader's Black Warhorse
	[70772]	= 9,	-- Blessed Healing
	[72081]	= 0,	-- Frozen Orb
	[1463]	= 60,	-- Mana Shield
	[8117]	= 1800,	-- Agility
	[8119]	= 1800,	-- Strength
	[14030]	= 6,	-- Hooked Net
	[16488]	= 5,	-- Blood Craze
	[18989]	= 0,	-- Gray Kodo
	[23829]	= 0,	-- Master Demonologist
	[46355]	= 300,	-- Blood Elf Illusion
	[48102]	= 1800,	-- Stamina
	[48108]	= 15,	-- Hot Streak
	[52419]	= 10,	-- Deflection
	[53301]	= 2,	-- Explosive Shot
	[55775]	= 15,	-- Swordguard Embroidery
	[57079]	= 3600,	-- Well Fed
	[57097]	= 3600,	-- Well Fed
	[59650]	= 0,	-- Black Drake
	[63250]	= 10,	-- Jouster's Fury
	[66721]	= 0,	-- Burning Fury
	[66725]	= 15,	-- Meteor Fists
	[66808]	= 15,	-- Meteor Fists
	[70760]	= 10,	-- Deliverance
	[71875]	= 10,	-- Necrotic Touch
	[71993]	= 0,	-- Frozen Mallet
	[72004]	= 20,	-- Frostbite
	[72034]	= 60,	-- Whiteout
	[72122]	= 0,	-- Frozen Mallet
	[467]	= 20,	-- Thorns
	[3219]	= 3600,	-- Weak Troll's Blood Elixir
	[6114]	= 300,	-- Raptor Punch
	[7294]	= 0,	-- Retribution Aura
	[7844]	= 3600,	-- Fire Power
	[8050]	= 18,	-- Flame Shock
	[8096]	= 1800,	-- Intellect
	[8314]	= 3600,	-- Rock Skin
	[11328]	= 3600,	-- Agility
	[12178]	= 1800,	-- Stamina
	[17038]	= 1200,	-- Winterfall Firewater
	[17628]	= 3600,	-- Supreme Power
	[19705]	= 900,	-- Well Fed
	[20154]	= 1800,	-- Seal of Righteousness
	[23760]	= 0,	-- Master Demonologist
	[28518]	= 3600,	-- Flask of Fortification
	[28694]	= 900,	-- Dreaming Glory
	[32296]	= 0,	-- Swift Yellow Wind Rider
	[33254]	= 1800,	-- Well Fed
	[36895]	= 3600,	-- Transporter Malfunction
	[36897]	= 3600,	-- Transporter Malfunction
	[44614]	= 9,	-- Frostfire Bolt
	[54216]	= 4,	-- Master's Call
	[57833]	= 4,	-- Frost Spit
	[58468]	= 3600,	-- Hugely Well Fed
	[58984]	= 0,	-- Shadowmeld
	[59230]	= 3600,	-- Well Fed
	[62305]	= 4,	-- Master's Call
	[67735]	= 0,	-- Volatility
	[67736]	= 20,	-- Volatile Power
	[1120]	= 15,	-- Drain Soul
	[17535]	= 3600,	-- Elixir of the Sages
	[18400]	= 0,	-- Piccolo of the Flaming Fire
	[21163]	= 1800,	-- Polished Armor
	[23225]	= 0,	-- Swift Green Mechanostrider
	[26276]	= 3600,	-- Greater Firepower
	[29175]	= 180,	-- Ribbon Dance
	[32240]	= 0,	-- Snowy Gryphon
	[32289]	= 0,	-- Swift Red Gryphon
	[33151]	= 10,	-- Surge of Light
	[44825]	= 0,	-- Flying Reindeer
	[56161]	= 6,	-- Glyph of Prayer of Healing
	[57054]	= 10,	-- Tranquility
	[57363]	= 3600,	-- Well Fed
	[63956]	= 0,	-- Ironbound Proto-Drake
	[72096]	= 60,	-- Whiteout
	[72098]	= 20,	-- Frostbite
	[72104]	= 5,	-- Freezing Ground
	[72121]	= 10,	-- Frostbite
	[73320]	= 600,	-- Frostborn Illusion
	[1120]	= 15,	-- Drain Soul
	[17535]	= 3600,	-- Elixir of the Sages
	[18400]	= 0,	-- Piccolo of the Flaming Fire
	[21163]	= 1800,	-- Polished Armor
	[23225]	= 0,	-- Swift Green Mechanostrider
	[26276]	= 3600,	-- Greater Firepower
	[29175]	= 180,	-- Ribbon Dance
	[32240]	= 0,	-- Snowy Gryphon
	[32289]	= 0,	-- Swift Red Gryphon
	[33151]	= 10,	-- Surge of Light
	[44825]	= 0,	-- Flying Reindeer
	[56161]	= 6,	-- Glyph of Prayer of Healing
	[57054]	= 10,	-- Tranquility
	[57363]	= 3600,	-- Well Fed
	[63956]	= 0,	-- Ironbound Proto-Drake
	[72096]	= 60,	-- Whiteout
	[72098]	= 20,	-- Frostbite
	[72104]	= 5,	-- Freezing Ground
	[72121]	= 10,	-- Frostbite
	[73320]	= 600,	-- Frostborn Illusion
	[469]	= 120,	-- Commanding Shout
	[586]	= 10,	-- Fade
	[744]	= 30,	-- Poison
	[774]	= 12,	-- Rejuvenation
	[3220]	= 3600,	-- Armor
	[6673]	= 120,	-- Battle Shout
	[11349]	= 3600,	-- Armor
	[12024]	= 5,	-- Net
	[19706]	= 900,	-- Well Fed
	[20798]	= 1800,	-- Demon Skin
	[28747]	= 600,	-- Frenzy
	[42728]	= 60,	-- Dreadful Roar
	[45716]	= 40,	-- Torch Tossing Training
	[47748]	= 45,	-- Rift Shield
	[48058]	= 30,	-- Crystal Bloom
	[50131]	= 10,	-- Draw Magic
	[52537]	= 10,	-- Fixate
	[53334]	= 9,	-- Animate Bones
	[53764]	= 3600,	-- Mighty Mana Regeneration
	[54314]	= 30,	-- Drain Power
	[54315]	= 30,	-- Drain Power
	[54497]	= 3600,	-- Lesser Armor
	[57056]	= 90,	-- Aura of Regeneration
	[57063]	= 10,	-- Arcane Attraction
	[63637]	= 0,	-- Darnassian Nightsaber
	[64904]	= 8,	-- Hymn of Hope
	[68720]	= 0,	-- Quarry
	[116]	= 9,	-- Frostbolt
	[133]	= 0,	-- Fireball
	[172]	= 18,	-- Corruption
	[589]	= 18,	-- Shadow Word: Pain
	[3248]	= 6,	-- Improved Blocking
	[13730]	= 30,	-- Demoralizing Shout
	[15572]	= 30,	-- Sunder Armor
	[16244]	= 30,	-- Demoralizing Shout
	[17464]	= 0,	-- Brown Skeletal Horse
	[25058]	= 15,	-- Renew
	[29341]	= 5,	-- Shadowburn
	[29882]	= 20,	-- Loose Mana
	[34410]	= 3600,	-- Hellscream's Warsong
	[35079]	= 4,	-- Misdirection
	[42705]	= 60,	-- Enrage
	[43182]	= 30,	-- Drink
	[43931]	= 15,	-- Rend
	[47543]	= 0,	-- Frozen Prison
	[47774]	= 120,	-- Frenzy
	[47781]	= 6,	-- Spellbreaker
	[47854]	= 0,	-- Frozen Prison
	[47981]	= 15,	-- Spell Reflection
	[56778]	= 60,	-- Mana Shield
	[60819]	= 10,	-- Libram of Reciprocation
	[61470]	= 0,	-- Grand Ice Mammoth
	[64843]	= 8,	-- Divine Hymn
	[66776]	= 0,	-- Rage
	[67811]	= 12,	-- Dagger Throw
	[68719]	= 0,	-- Oil Refinery
	[68722]	= 2,	-- Oil Refinery
	[71877]	= 10,	-- Necrotic Touch
	[348]	= 15,	-- Immolate
	[755]	= 3,	-- Health Funnel
	[980]	= 24,	-- Bane of Agony
	[1130]	= 300,	-- Hunter's Mark
	[5262]	= 10,	-- Fanatic Blade
	[5782]	= 20,	-- Fear
	[6268]	= 3,	-- Rushing Charge
	[6278]	= 60,	-- Creeping Mold
	[8042]	= 8,	-- Earth Shock
	[12541]	= 600,	-- Ghoul Rot
	[18070]	= 30,	-- Earthborer Acid
	[18267]	= 30,	-- Curse of Weakness
	[29334]	= 3600,	-- Toasted Smorc
	[40192]	= 0,	-- Ashes of Al'ar
	[46221]	= 180,	-- Animal Blood
	[47791]	= 5,	-- Arcane Haste
	[48400]	= 20,	-- Frost Tomb
	[53520]	= 4,	-- Carrion Beetles
	[54309]	= 10,	-- Mark of Darkness
	[54955]	= 5,	-- Ticking Bomb
	[58493]	= 3600,	-- Mohawked!
	[68298]	= 5,	-- Parachute
	[68377]	= 0,	-- Carrying Huge Seaforium
	[71579]	= 20,	-- Elusive Power
	[99]	= 30,	-- Demoralizing Roar
	[126]	= 45,	-- Eye of Kilrogg
	[5280]	= 45,	-- Razor Mane
	[6950]	= 60,	-- Faerie Fire
	[8076]	= 0,	-- Strength of Earth
	[8202]	= 1200,	-- Sapta Sight
	[8242]	= 2,	-- Shield Slam
	[12292]	= 30,	-- Death Wish
	[18266]	= 15,	-- Curse of Agony
	[20800]	= 21,	-- Immolate
	[29235]	= 3600,	-- Fire Festival Fortitude
	[42702]	= 10,	-- Decrepify
	[42740]	= 8,	-- Njord's Rune of Protection
	[43664]	= 15,	-- Unholy Rage
	[46899]	= 900,	-- Well Fed
	[48095]	= 0,	-- Intense Cold
	[52446]	= 10,	-- Acid Splash
	[52470]	= 8,	-- Enrage
	[52493]	= 10,	-- Poison Spray
	[53322]	= 6,	-- Crushing Webs
	[53330]	= 20,	-- Infected Wound
	[54494]	= 3600,	-- Major Agility
	[57139]	= 3600,	-- Well Fed
	[58502]	= 7200,	-- Scared
	[60486]	= 10,	-- Illustration of the Dragon Soul
	[64861]	= 15,	-- Precision Shots
	[65638]	= 0,	-- Swift Moonsaber
	[66550]	= 20,	-- Teleport
	[432]	= 24,	-- Drink
	[702]	= 120,	-- Curse of Weakness
	[6343]	= 30,	-- Thunder Clap
	[8599]	= 120,	-- Enrage
	[11348]	= 3600,	-- Greater Armor
	[11390]	= 3600,	-- Arcane Elixir
	[20043]	= 0,	-- Aspect of the Wild
	[25207]	= 1800,	-- Amulet of the Moon
	[27817]	= 6,	-- Blessed Recovery
	[31403]	= 120,	-- Battle Shout
	[35944]	= 30,	-- Power Word: Shield
	[39171]	= 5,	-- Mortal Strike
	[47283]	= 8,	-- Empowered Imp
	[53467]	= 15,	-- Leeching Swarm
	[53602]	= 12,	-- Dart
	[53801]	= 600,	-- Frenzy
	[54965]	= 8,	-- Bolthorn's Rune of Flame
	[57580]	= 5,	-- Lightning Infusion
	[60344]	= 3600,	-- Expertise
	[63643]	= 0,	-- Forsaken Warhorse
	[64057]	= 3600,	-- Well Fed
	[65014]	= 10,	-- Pyrite Infusion
	[68652]	= 0,	-- Honorable Defender
	[71568]	= 20,	-- Urgency
	[71870]	= 10,	-- Blessing of Light
	[72221]	= 0,	-- Luck of the Draw
	[580]	= 0,	-- Timber Wolf
	[687]	= 1800,	-- Demon Armor
	[8936]	= 6,	-- Regrowth
	[17462]	= 0,	-- Red Skeletal Horse
	[19709]	= 900,	-- Well Fed
	[21049]	= 30,	-- Bloodlust
	[28521]	= 3600,	-- Flask of Blinding Light
	[33702]	= 15,	-- Blood Fury
	[36702]	= 0,	-- Fiery Warhorse
	[37578]	= 5,	-- Debilitating Strike
	[38232]	= 20,	-- Battle Shout
	[42723]	= 2,	-- Dark Smash
	[45444]	= 0,	-- Bonfire's Blessing
	[46352]	= 3600,	-- Fire Festival Fury
	[47699]	= 300,	-- Crystal Bark
	[47747]	= 45,	-- Charge Rifts
	[53030]	= 10,	-- Leech Poison
	[53317]	= 15,	-- Rend
	[53468]	= 1,	-- Leeching Swarm
	[55077]	= 5,	-- Pounce
	[56827]	= 60,	-- Aura of Arcane Haste
	[57086]	= 0,	-- Frenzy
	[58448]	= 1800,	-- Strength
	[67332]	= 20,	-- Flaming Cinder
	[68160]	= 15,	-- Meteor Fists
	[68161]	= 15,	-- Meteor Fists
	[113]	= 15,	-- Chains of Ice
	[853]	= 6,	-- Hammer of Justice
	[1127]	= 27,	-- Food
	[3603]	= 15,	-- Distracting Pain
	[5171]	= 6,	-- Slice and Dice
	[5213]	= 15,	-- Molten Metal
	[6432]	= 10,	-- Smite Stomp
	[6466]	= 3,	-- Axe Toss
	[6713]	= 5,	-- Disarm
	[7483]	= 300,	-- Howling Rage
	[7484]	= 300,	-- Howling Rage
	[7947]	= 60,	-- Localized Toxin
	[7948]	= 20,	-- Wild Regeneration
	[8898]	= 1200,	-- Sapta Sight
	[9128]	= 120,	-- Battle Shout
	[17627]	= 3600,	-- Distilled Wisdom
	[20707]	= 900,	-- Soulstone Resurrection
	[22766]	= 0,	-- Sneak
	[25746]	= 15,	-- Damage Absorb
	[27863]	= 600,	-- The Baron's Ultimatum
	[28273]	= 600,	-- Bloodthistle
	[29073]	= 30,	-- Food
	[29333]	= 3600,	-- Midsummer Sausage
	[41635]	= 30,	-- Prayer of Mending
	[47779]	= 4,	-- Arcane Torrent
	[48100]	= 1800,	-- Intellect
	[51714]	= 20,	-- Frost Vulnerability
	[56969]	= 8,	-- Arcane Blast
	[58452]	= 1800,	-- Armor
	[60299]	= 20,	-- Incisor Fragment
	[62380]	= 3600,	-- Lesser Flask of Resistance
	[63438]	= 0,	-- Silvermoon Champion's Pennant
	[65081]	= 4,	-- Body and Soul
	[71175]	= 15,	-- Agile
	[122]	= 8,	-- Frost Nova
	[6016]	= 20,	-- Pierce Armor
	[6253]	= 2,	-- Backhand
	[7038]	= 60,	-- Forsaken Skill: Swords
	[7039]	= 60,	-- Forsaken Skill: Axes
	[7040]	= 60,	-- Forsaken Skill: Daggers
	[7041]	= 60,	-- Forsaken Skill: Maces
	[7042]	= 60,	-- Forsaken Skill: Staves
	[7044]	= 60,	-- Forsaken Skill: Guns
	[7045]	= 60,	-- Forsaken Skill: 2H Axes
	[8040]	= 15,	-- Druid's Slumber
	[9672]	= 4,	-- Frostbolt
	[11977]	= 15,	-- Rend
	[16739]	= 300,	-- Orb of Deception
	[20006]	= 12,	-- Unholy Curse
	[30991]	= 0,	-- Stealth
	[51209]	= 10,	-- Hungering Cold
	[52109]	= 0,	-- Flametongue Totem
	[58891]	= 45,	-- Wild Magic
	[70639]	= 8,	-- Call of Sylvanas
	[430]	= 18,	-- Drink
	[431]	= 21,	-- Drink
	[435]	= 24,	-- Food
	[700]	= 20,	-- Sleep
	[1079]	= 16,	-- Rip
	[5277]	= 15,	-- Evasion
	[6306]	= 30,	-- Acid Splash
	[7046]	= 60,	-- Forsaken Skill: 2H Maces
	[7047]	= 60,	-- Forsaken Skill: 2H Swords
	[7049]	= 60,	-- Forsaken Skill: Fire
	[7053]	= 60,	-- Forsaken Skill: Shadow
	[7057]	= 300,	-- Haunting Spirits
	[7068]	= 15,	-- Veil of Shadow
	[7072]	= 60,	-- Wild Rage
	[7074]	= 5,	-- Screams of the Past
	[7295]	= 10,	-- Soul Drain
	[7812]	= 30,	-- Sacrifice
	[8041]	= 10,	-- Serpent Form
	[8066]	= 120,	-- Shrink
	[8112]	= 1800,	-- Spirit
	[8365]	= 10,	-- Enlarge
	[8379]	= 10,	-- Disarm
	[14143]	= 20,	-- Remorseless
	[14914]	= 7,	-- Holy Fire
	[30482]	= 1800,	-- Molten Armor
	[33720]	= 3600,	-- Onslaught Elixir
	[42777]	= 0,	-- Swift Spectral Tiger
	[56112]	= 10,	-- Furious Attacks
	[543]	= 30,	-- Mage Ward
	[703]	= 18,	-- Garrote
	[1850]	= 15,	-- Dash
	[7051]	= 60,	-- Forsaken Skill: Holy
	[7054]	= 300,	-- Forsaken Skills
	[7121]	= 10,	-- Anti-Magic Shield
	[7124]	= 300,	-- Arugal's Gift
	[7125]	= 120,	-- Toxic Saliva
	[7127]	= 60,	-- Wavering Will
	[7481]	= 300,	-- Howling Rage
	[7621]	= 10,	-- Arugal's Curse
	[8140]	= 15,	-- Befuddlement
	[8148]	= 60,	-- Thorns Aura
	[8153]	= 0,	-- Owl Form
	[16490]	= 5,	-- Blood Craze
	[18381]	= 30,	-- Cripple
	[19386]	= 30,	-- Wyvern Sting
	[19434]	= 0,	-- Aimed Shot
	[26522]	= 1800,	-- Lunar Fortune
	[28274]	= 1200,	-- Bloodthistle Withdrawal
	[29332]	= 3600,	-- Fire-toasted Bun
	[29335]	= 3600,	-- Elderberry Pie
	[53386]	= 30,	-- Cinderglacier
	[58496]	= 7200,	-- Sad
	[71345]	= 0,	-- Big Love Rocket
	[434]	= 21,	-- Food
	[689]	= 3,	-- Drain Life
	[853]	= 6,	-- Hammer of Justice
	[1159]	= 6,	-- First Aid
	[1160]	= 30,	-- Demoralizing Shout
	[2944]	= 24,	-- Devouring Plague
	[2983]	= 8,	-- Sprint
	[3427]	= 30,	-- Infected Wound
	[5115]	= 6,	-- Battle Command
	[5159]	= 20,	-- Melt Ore
	[6136]	= 5,	-- Chilled
	[7140]	= 5,	-- Expose Weakness
	[7389]	= 15,	-- Attack
	[7399]	= 4,	-- Terrify
	[8056]	= 8,	-- Frost Shock
	[8101]	= 1800,	-- Stamina
	[8382]	= 45,	-- Leech Poison
	[8398]	= 8,	-- Frostbolt Volley
	[11113]	= 3,	-- Blast Wave
	[11640]	= 15,	-- Renew
	[12548]	= 8,	-- Frost Shock
	[13704]	= 6,	-- Psychic Scream
	[13797]	= 15,	-- Immolation Trap
	[14251]	= 30,	-- Riposte
	[16689]	= 45,	-- Nature's Grasp
	[18610]	= 8,	-- First Aid
	[21069]	= 6,	-- Larva Goo
	[23600]	= 6,	-- Piercing Howl
	[23768]	= 7200,	-- Sayge's Dark Fortune of Damage
	[24870]	= 900,	-- Well Fed
	[33053]	= 7200,	-- Mr Pinchy's Blessing
	[35712]	= 0,	-- Great Green Elekk
	[43197]	= 1800,	-- Spirit
	[45062]	= 0,	-- Holy Energy
	[45693]	= 0,	-- Torches Caught
	[51466]	= 0,	-- Elemental Oath
	[53909]	= 15,	-- Wild Magic
	[56352]	= 12,	-- Storm Punch
	[64128]	= 4,	-- Body and Soul
	[69180]	= 30,	-- Gutgore Ripper
	[453]	= 15,	-- Mind Soothe
	[2602]	= 15,	-- Fire Shield IV
	[3583]	= 60,	-- Deadly Poison
	[3604]	= 8,	-- Tendon Rip
	[5137]	= 60,	-- Call of the Grave
	[5211]	= 4,	-- Bash
	[5217]	= 6,	-- Tiger's Fury
	[6726]	= 5,	-- Silence
	[6742]	= 30,	-- Bloodlust
	[8263]	= 0,	-- Elemental Protection Totem Aura
	[8267]	= 600,	-- Cursed Blood
	[10730]	= 10,	-- Pacify
	[10734]	= 3,	-- Hail Storm
	[10838]	= 8,	-- First Aid
	[11397]	= 300,	-- Diseased Shot
	[11445]	= 60,	-- Bone Armor
	[11876]	= 5,	-- War Stomp
	[12255]	= 900,	-- Curse of Tuten'kash
	[12946]	= 10,	-- Putrid Stench
	[13812]	= 20,	-- Explosive Trap
	[13864]	= 1800,	-- Power Word: Fortitude
	[14515]	= 15,	-- Dominate Mind
	[15976]	= 10,	-- Puncture
	[20615]	= 3,	-- Intercept
	[21062]	= 30,	-- Putrid Breath
	[28703]	= 900,	-- Netherbloom Pollen
	[32727]	= 0,	-- Arena Preparation
	[43195]	= 1800,	-- Intellect
	[51945]	= 12,	-- Earthliving
	[55012]	= 0,	-- Lok'lira's Bargain
	[465]	= 0,	-- Devotion Aura
	[676]	= 10,	-- Disarm
	[1822]	= 9,	-- Rake
	[3222]	= 3600,	-- Strong Troll's Blood Elixir
	[3639]	= 6,	-- Improved Blocking
	[3742]	= 15,	-- Static Electricity
	[5403]	= 6,	-- Crash of Waves
	[5413]	= 120,	-- Noxious Catalyst
	[6940]	= 12,	-- Hand of Sacrifice
	[7964]	= 4,	-- Smoke Bomb
	[7966]	= 60,	-- Thorns Aura
	[8391]	= 3,	-- Ravage
	[8399]	= 10,	-- Sleep
	[8990]	= 0,	-- Retribution Aura
	[10348]	= 20,	-- Tune Up
	[10831]	= 5,	-- Reflection Field
	[11641]	= 10,	-- Hex
	[11971]	= 30,	-- Sunder Armor
	[12531]	= 8,	-- Chilling Touch
	[12627]	= 0,	-- Disease Cloud
	[12795]	= 120,	-- Frenzy
	[12890]	= 15,	-- Deep Slumber
	[12891]	= 45,	-- Acid Breath
	[13218]	= 15,	-- Wound Poison
	[13326]	= 1800,	-- Arcane Intellect
	[13532]	= 10,	-- Thunder Clap
	[14032]	= 18,	-- Shadow Word: Pain
	[18972]	= 20,	-- Slow
	[20925]	= 0,	-- Holy Shield
	[21909]	= 8,	-- Dust Field
	[24425]	= 7200,	-- Spirit of Zandalar
	[25606]	= 1800,	-- Pendant of the Agate Shield
	[25694]	= 900,	-- Well Fed
	[25702]	= 21,	-- Food
	[25941]	= 900,	-- Well Fed
	[28489]	= 3600,	-- Camouflage
	[30931]	= 20,	-- Battle Shout
	[31643]	= 8,	-- Blazing Speed
	[32736]	= 5,	-- Mortal Strike
	[39318]	= 0,	-- Tan Riding Talbuk
	[60343]	= 3600,	-- Mighty Defense
	[60518]	= 10,	-- Touched by a Troll
	[61451]	= 0,	-- Flying Carpet
	[63735]	= 20,	-- Serendipity
	[66684]	= 20,	-- Flaming Cinder
	[70845]	= 10,	-- Stoicism
	[71866]	= 6,	-- Fountain of Light
	[72282]	= 0,	-- Invincible
	[74960]	= 10,	-- Infrigidate
	[75731]	= 0,	-- Instant Statue
	[139]	= 12,	-- Renew
	[408]	= 1,	-- Kidney Shot
	[3267]	= 7,	-- First Aid
	[8068]	= 1800,	-- Healthy Spirit
	[8078]	= 10,	-- Thunderclap
	[9007]	= 18,	-- Pounce Bleed
	[9034]	= 21,	-- Immolate
	[9438]	= 8,	-- Arcane Bubble
	[9482]	= 30,	-- Amplify Flames
	[11366]	= 12,	-- Pyroblast
	[11426]	= 60,	-- Ice Barrier
	[11442]	= 180,	-- Withered Touch
	[12484]	= 2,	-- Chilled
	[12528]	= 10,	-- Silence
	[14201]	= 9,	-- Enrage
	[15087]	= 15,	-- Evasion
	[15971]	= 30,	-- Demoralizing Roar
	[16177]	= 15,	-- Ancestral Fortitude
	[19891]	= 0,	-- Resistance Aura
	[24379]	= 10,	-- Restoration
	[24394]	= 3,	-- Intimidation
	[24712]	= 3600,	-- Leper Gnome Costume
	[25859]	= 0,	-- Reindeer
	[29544]	= 6,	-- Frightening Shout
	[31125]	= 4,	-- Blade Twisting
	[34976]	= 0,	-- Netherstorm Flag
	[48103]	= 1800,	-- Spirit
	[52909]	= 1800,	-- Water Breathing
	[58451]	= 1800,	-- Agility
	[59675]	= 1800,	-- Nexus Residue
	[59676]	= 1800,	-- Residue of Darkness
	[63896]	= 12,	-- Bullheaded
	[64343]	= 10,	-- Impact
	[70747]	= 30,	-- Quad Core
	[71485]	= 30,	-- Agility of the Vrykul
	[1135]	= 30,	-- Drink
	[1137]	= 30,	-- Drink
	[1490]	= 300,	-- Curse of the Elements
	[3815]	= 45,	-- Poison Cloud
	[7992]	= 25,	-- Slowing Poison
	[8282]	= 120,	-- Curse of Blood
	[8285]	= 2.5,	-- Rampage
	[8600]	= 180,	-- Fevered Plague
	[9275]	= 21,	-- Immolate
	[10732]	= 10,	-- Supercharge
	[11131]	= 10,	-- Icicle
	[11980]	= 120,	-- Curse of Weakness
	[12097]	= 20,	-- Pierce Armor
	[12245]	= 300,	-- Infected Spine
	[16277]	= 15,	-- Flurry
	[16914]	= 10,	-- Hurricane
	[21007]	= 120,	-- Curse of Weakness
	[21337]	= 600,	-- Thorns
	[26008]	= 1800,	-- Toast
	[33726]	= 3600,	-- Elixir of Mastery
	[44415]	= 3,	-- Blackout
	[45245]	= 1800,	-- Well Fed
	[45724]	= 0,	-- Braziers Hit!
	[48838]	= 10,	-- Elemental Tenacity
	[51399]	= 3,	-- Death Grip
	[54443]	= 20,	-- Demonic Empowerment
	[62146]	= 30,	-- Unflinching Valor
	[67380]	= 20,	-- Evasion
	[70244]	= 3600,	-- "Wizardry" Cologne
	[120]	= 8,	-- Cone of Cold
	[710]	= 30,	-- Banish
	[3356]	= 45,	-- Flame Lash
	[5677]	= 0,	-- Mana Spring
	[6146]	= 15,	-- Slow
	[7739]	= 10,	-- Inferno Shell
	[8269]	= 120,	-- Frenzy
	[8281]	= 6,	-- Sonic Burst
	[8377]	= 4,	-- Earthgrab
	[8788]	= 600,	-- Lightning Shield
	[9798]	= 0,	-- Radiation
	[11327]	= 3,	-- Vanish
	[12248]	= 10,	-- Amplify Damage
	[12251]	= 30,	-- Virulent Poison
	[12421]	= 2,	-- Mithril Frag Bomb
	[12540]	= 4,	-- Gouge
	[12884]	= 45,	-- Acid Breath
	[13439]	= 5,	-- Frostbolt
	[15407]	= 3,	-- Mind Flay
	[17154]	= 30,	-- The Green Tower
	[21655]	= 1,	-- Blink
	[32292]	= 0,	-- Swift Purple Gryphon
	[36899]	= 3600,	-- Transporter Malfunction
	[59843]	= 600,	-- Underbelly Elixir
	[65637]	= 0,	-- Great Red Elekk
	[2601]	= 30,	-- Fire Shield III
	[5246]	= 8,	-- Intimidating Shout
	[6789]	= 3,	-- Death Coil
	[9256]	= 10,	-- Deep Sleep
	[9459]	= 60,	-- Corrosive Ooze
	[10452]	= 20,	-- Flame Buffet
	[11020]	= 8,	-- Petrify
	[11922]	= 15,	-- Entangling Roots
	[11962]	= 15,	-- Immolate
	[11974]	= 30,	-- Power Word: Shield
	[12461]	= 2,	-- Backhand
	[12493]	= 120,	-- Curse of Weakness
	[14517]	= 30,	-- Crusader Strike
	[15039]	= 12,	-- Flame Shock
	[15531]	= 8,	-- Frost Nova
	[20875]	= 900,	-- Rumsey Rum
	[29674]	= 0,	-- Lesser Shielding
	[38254]	= 1800,	-- Festering Wound
	[49623]	= 15,	-- Effervescence
	[59125]	= 120,	-- Lucky
	[75458]	= 15,	-- Piercing Twilight
	[3419]	= 6,	-- Improved Blocking
	[6728]	= 10,	-- Enveloping Winds
	[8275]	= 75,	-- Poisoned Shot
	[8988]	= 10,	-- Silence
	[9080]	= 10,	-- Hamstring
	[9906]	= 5,	-- Reflection
	[11443]	= 15,	-- Cripple
	[11639]	= 18,	-- Shadow Word: Pain
	[11647]	= 30,	-- Power Word: Shield
	[11820]	= 6,	-- Electrified Net
	[12096]	= 8,	-- Fear
	[12098]	= 20,	-- Sleep
	[13298]	= 30,	-- Poison
	[19710]	= 900,	-- Well Fed
	[21067]	= 10,	-- Poison Bolt
	[21331]	= 15,	-- Entangling Roots
	[24709]	= 3600,	-- Pirate Costume
	[36893]	= 3600,	-- Transporter Malfunction
	[39628]	= 3600,	-- Elixir of Ironskin
	[46630]	= 90,	-- Torch Tossing Practice
	[50263]	= 20,	-- Quickness of the Sailor
	[57529]	= 0,	-- Arcane Potency
	[61425]	= 0,	-- Traveler's Tundra Mammoth
	[65780]	= 300,	-- Pink Gumball
	[71560]	= 30,	-- Speed of the Vrykul
	[740]	= 8,	-- Tranquility
	[745]	= 5,	-- Web
	[1129]	= 30,	-- Food
	[1133]	= 27,	-- Drink
	[1943]	= 6,	-- Rupture
	[2818]	= 12,	-- Deadly Poison
	[3256]	= 240,	-- Plague Cloud
	[3439]	= 300,	-- Wandering Plague
	[4318]	= 1800,	-- Guile of the Raptor
	[5005]	= 21,	-- Food
	[5138]	= 3,	-- Drain Mana
	[6524]	= 2,	-- Ground Tremor
	[6533]	= 2,	-- Net
	[8258]	= 240,	-- Devotion Aura
	[8362]	= 20,	-- Renew
	[9775]	= 60,	-- Irradiated
	[10093]	= 1,	-- Harsh Winds
	[11264]	= 10,	-- Ice Blast
	[11436]	= 10,	-- Slow
	[12040]	= 30,	-- Shadow Shield
	[12294]	= 10,	-- Mortal Strike
	[12479]	= 10,	-- Hex of Jammal'an
	[12486]	= 1.5,	-- Chilled
	[12530]	= 60,	-- Frailty
	[12611]	= 8,	-- Cone of Cold
	[12741]	= 120,	-- Curse of Weakness
	[13445]	= 15,	-- Rend
	[13526]	= 30,	-- Corrosive Poison
	[14518]	= 30,	-- Crusader Strike
	[15532]	= 8,	-- Frost Nova
	[15548]	= 10,	-- Thunderclap
	[17537]	= 3600,	-- Elixir of Brute Force
	[21068]	= 24,	-- Corruption
	[21547]	= 5,	-- Spore Cloud
	[21687]	= 15,	-- Toxic Volley
	[21749]	= 2,	-- Thorn Volley
	[21787]	= 120,	-- Deadly Poison
	[23759]	= 0,	-- Master Demonologist
	[23767]	= 7200,	-- Sayge's Dark Fortune of Armor
	[25747]	= 15,	-- Damage Absorb
	[28509]	= 3600,	-- Greater Mana Regeneration
	[33082]	= 1800,	-- Strength
	[33259]	= 1800,	-- Well Fed
	[34709]	= 15,	-- Shadow Sight
	[42792]	= 3,	-- Recently Dropped Flag
	[45694]	= 180,	-- Captain Rumsey's Lager
	[45699]	= 5,	-- Flames of Failure
	[47057]	= 180,	-- Fiery Seduction
	[48333]	= 300,	-- Going Ape
	[49962]	= 17,	-- Jungle Madness!
	[50872]	= 30,	-- Savagery
	[56521]	= 1800,	-- Blessing of Wisdom
	[56525]	= 1800,	-- Blessing of Kings
	[57514]	= 12,	-- Enrage
	[60517]	= 20,	-- Talisman of Troll Divinity
	[63311]	= 8,	-- Shadowsnare
	[64937]	= 5,	-- Heightened Reflexes
	[74855]	= 0,	-- Blazing Hippogryph
	[16278]	= 15,	-- Flurry
	[20052]	= 15,	-- Conviction
	[34914]	= 15,	-- Vampiric Touch
	[49868]	= 0,	-- Mind Quickening
	[53290]	= 0,	-- Hunting Party
	[73681]	= 12,	-- Unleash Wind
	[73683]	= 8,	-- Unleash Flame
	[77487]	= 60,	-- Shadow Orb
	[77661]	= 15,	-- Searing Flames
	[79063]	= 3600,	-- Blessing of Kings
	[79105]	= 3600,	-- Power Word: Fortitude
	[79107]	= 3600,	-- Shadow Protection
	[82661]	= 0,	-- Aspect of the Fox
	[85509]	= 20,	-- Denounce
	[85767]	= 1800,	-- Dark Intent
	[85768]	= 1800,	-- Dark Intent
	[86273]	= 6,	-- Illuminated Healing
	[87118]	= 15,	-- Dark Evangelism
	[87153]	= 18,	-- Dark Archangel
	[91724]	= 0,	-- Spell Warding
	[17]	= 30,	-- Power Word: Shield
	[879]	= 6,	-- Exorcism
	[1714]	= 30,	-- Curse of Tongues
	[8122]	= 8,	-- Psychic Scream
	[32389]	= 12,	-- Shadow Embrace
	[44457]	= 12,	-- Living Bomb
	[44544]	= 15,	-- Fingers of Frost
	[47960]	= 6,	-- Shadowflame
	[50435]	= 10,	-- Chilblains
	[51460]	= 3,	-- Runic Corruption
	[51698]	= 0,	-- Honor Among Thieves
	[65142]	= 21,	-- Ebon Plague
	[73413]	= 1800,	-- Inner Will
	[73651]	= 0,	-- Recuperate
	[73975]	= 15,	-- Necrotic Strike
	[76691]	= 0,	-- Vengeance
	[77613]	= 15,	-- Grace
	[79058]	= 3600,	-- Arcane Brilliance
	[80354]	= 600,	-- Temporal Displacement
	[81326]	= 0,	-- Brittle Bones
	[83302]	= 4,	-- Improved Cone of Cold
	[85673]	= 6,	-- Word of Glory
	[87098]	= 8,	-- Invocation
	[88611]	= 1,	-- Smoke Bomb
	[88819]	= 12,	-- Daybreak
	[91021]	= 10,	-- Find Weakness
	[91342]	= 30,	-- Shadow Infusion
	[1134]	= 15,	-- Inner Rage
	[30108]	= 15,	-- Unstable Affliction
	[48181]	= 12,	-- Haunt
	[53646]	= 0,	-- Demonic Pact
	[54729]	= 0,	-- Winged Steed of the Ebon Blade
	[57519]	= 12,	-- Enrage
	[77616]	= 20,	-- Dark Simulacrum
	[77747]	= 0,	-- Totemic Wrath
	[79061]	= 3600,	-- Mark of the Wild
	[79102]	= 3600,	-- Blessing of Might
	[79140]	= 30,	-- Vendetta
	[79683]	= 20,	-- Arcane Missiles!
	[82930]	= 0,	-- Arcane Tactics
	[84586]	= 15,	-- Slaughter
	[84620]	= 10,	-- Hold the Line
	[84958]	= 20,	-- Tranquilized
	[85388]	= 5,	-- Throwdown
	[85730]	= 10,	-- Deadly Calm
	[86346]	= 6,	-- Colossus Smash
	[86627]	= 10,	-- Incite
	[93068]	= 15,	-- Master Poisoner
	[94009]	= 15,	-- Rend
	[82327]	= 10,	-- Holy Radiance
	[85497]	= 4,	-- Speed of Light
	[32645]	= 1,	-- Envenom
	[974]	= 600,	-- Earth Shield
	[1978]	= 15,	-- Serpent Sting
	[3674]	= 15,	-- Black Arrow
	[5570]	= 12,	-- Insect Swarm
	[5916]	= 0,	-- Shadowstalker Stealth
	[6229]	= 30,	-- Shadow Ward
	[8185]	= 0,	-- Elemental Resistance
	[8921]	= 12,	-- Moonfire
	[11538]	= 4,	-- Frostbolt
	[12355]	= 2,	-- Impact
	[17767]	= 6,	-- Consume Shadows
	[23145]	= 16,	-- Dive
	[33876]	= 60,	-- Mangle
	[37548]	= 3,	-- Taunt
	[51700]	= 0,	-- Honor Among Thieves
	[61044]	= 15,	-- Demoralizing Shout
	[64803]	= 4,	-- Entrapment
	[74001]	= 30,	-- Combat Readiness
	[74002]	= 6,	-- Combat Insight
	[77606]	= 8,	-- Dark Simulacrum
	[79057]	= 3600,	-- Arcane Brilliance
	[79060]	= 3600,	-- Mark of the Wild
	[79268]	= 9,	-- Soul Harvest
	[80353]	= 40,	-- Time Warp
	[81340]	= 10,	-- Sudden Doom
	[82365]	= 10,	-- Skull Bash
	[82368]	= 20,	-- Victorious
	[82654]	= 30,	-- Widow Venom
	[84721]	= 2,	-- Frostfire Orb
	[86000]	= 15,	-- Curse of Gul'dan
	[86211]	= 20,	-- Soul Swap
	[88466]	= 9,	-- Serpent Sting
	[89775]	= 24,	-- Hemorrhage
	[91565]	= 300,	-- Faerie Fire
	[91800]	= 3,	-- Gnaw
	[71]	= 0,	-- Defensive Stance
	[136]	= 10,	-- Mend Pet
	[2457]	= 0,	-- Battle Stance
	[2458]	= 0,	-- Berserker Stance
	[9005]	= 3,	-- Pounce
	[14202]	= 9,	-- Enrage
	[16191]	= 0,	-- Mana Tide
	[22570]	= 0,	-- Maim
	[24131]	= 6,	-- Wyvern Sting
	[24844]	= 45,	-- Lightning Breath
	[30213]	= 6,	-- Legion Strike
	[30283]	= 3,	-- Shadowfury
	[48020]	= 1,	-- Demonic Circle: Teleport
	[48438]	= 7,	-- Wild Growth
	[51755]	= 60,	-- Camouflage
	[55328]	= 15,	-- Stoneclaw Totem
	[55342]	= 30,	-- Mirror Image
	[59888]	= 6,	-- Borrowed Time
	[61295]	= 15,	-- Riptide
	[63058]	= 20,	-- Glyph of Amberskin Protection
	[63560]	= 30,	-- Dark Transformation
	[64901]	= 8,	-- Hymn of Hope
	[73685]	= 8,	-- Unleash Life
	[74434]	= 15,	-- Soulburn
	[77535]	= 10,	-- Blood Shield
	[77769]	= 15,	-- Trap Launcher
	[77800]	= 8,	-- Focused Insight
	[79101]	= 3600,	-- Blessing of Might
	[79104]	= 3600,	-- Power Word: Fortitude
	[79206]	= 10,	-- Spiritwalker's Grace
	[79438]	= 8,	-- Soulburn: Demonic Circle
	[79460]	= 20,	-- Demon Soul: Felhunter
	[80886]	= 0,	-- Primal Madness
	[81141]	= 10,	-- Blood Swarm
	[81256]	= 12,	-- Dancing Rune Weapon
	[81277]	= 0,	-- Blood Gorged
	[81781]	= 25,	-- Power Word: Barrier
	[82691]	= 10,	-- Ring of Frost
	[82692]	= 15,	-- Focus Fire
	[82897]	= 8,	-- Resistance is Futile!
	[82925]	= 30,	-- Ready, Set, Aim...
	[83073]	= 6,	-- Shattered Barrier
	[83154]	= 9,	-- Piercing Chill
	[84963]	= 4,	-- Inquisition
	[85421]	= 7,	-- Burning Embers
	[85696]	= 20,	-- Zealotry
	[85739]	= 10,	-- Meat Cleaver
	[86669]	= 30,	-- Guardian of Ancient Kings Summon
	[87173]	= 4,	-- Long Arm of the Law
	[88448]	= 10,	-- Demonic Rebirth
	[89388]	= 12,	-- Sic 'Em!
	[89420]	= 1.5,	-- Drain Life
	[89485]	= 0,	-- Inner Focus
	[89751]	= 6,	-- Felstorm
	[89766]	= 4,	-- Axe Toss
	[89906]	= 10,	-- Judgements of the Bold
	[90174]	= 8,	-- Hand of Light
	[90315]	= 30,	-- Tailspin
	[90364]	= 0,	-- Qiraji Fortitude
	[91711]	= 30,	-- Nether Ward
	[91807]	= 2,	-- Shambling Rush
	[66]	= 3,	-- Invisibility
	[603]	= 60,	-- Bane of Doom
	[1742]	= 6,	-- Cower
	[1949]	= 15,	-- Hellfire
	[2812]	= 3,	-- Holy Wrath
	[14183]	= 20,	-- Premeditation
	[17057]	= 6,	-- Furor
	[19306]	= 5,	-- Counterattack
	[19577]	= 15,	-- Intimidation
	[31117]	= 5,	-- Unstable Affliction
	[31850]	= 10,	-- Ardent Defender
	[31930]	= 10,	-- Judgements of the Wise
	[31935]	= 3,	-- Avenger's Shield
	[32409]	= 1,	-- Shadow Word: Death
	[33878]	= 60,	-- Mangle
	[51185]	= 0,	-- King of the Jungle
	[54706]	= 5,	-- Venom Web Spray
	[64382]	= 10,	-- Shattering Throw
	[77489]	= 6,	-- Echo of Light
	[77758]	= 6,	-- Thrash
	[79440]	= 6,	-- Soulburn: Searing Pain
	[81017]	= 8,	-- Stampede
	[81022]	= 10,	-- Stampede
	[81162]	= 8,	-- Will of the Necropolis
	[81206]	= 30,	-- Chakra: Prayer of Healing
	[81262]	= 7,	-- Efflorescence
	[81325]	= 0,	-- Brittle Bones
	[85383]	= 15,	-- Improved Soul Fire
	[85416]	= 2,	-- Grand Crusader
	[85433]	= 15,	-- Sacred Duty
	[86659]	= 12,	-- Guardian of Ancient Kings Summon
	[87342]	= 20,	-- Holy Shield
	[88063]	= 6,	-- Guarded by the Light
	[90785]	= 0.4,	-- Glyph of Power Word: Barrier
	[91797]	= 4,	-- Monstrous Blow
	[94528]	= 20,	-- Flare
	[26573]	= 10,	-- Consecration
	[30151]	= 6,	-- Pursuit
	[54786]	= 2,	-- Demon Leap
	[79106]	= 3600,	-- Shadow Protection
	[81208]	= 30,	-- Chakra: Heal
	[87096]	= 20,	-- Thunderstruck
	[88684]	= 6,	-- Holy Word: Serenity
	[90361]	= 10,	-- Spirit Mend
	[93435]	= 60,	-- Roar of Courage
	[93987]	= 3,	-- Aura of Foreboding
	[19883]	= 0,	-- Track Humanoids
	[32216]	= 20,	-- Victorious
	[48025]	= 0,	-- Headless Horseman's Mount
	[51789]	= 10,	-- Blade Barrier
	[66251]	= 8,	-- Launch
	[79459]	= 30,	-- Demon Soul: Imp
	[83046]	= 1.5,	-- Improved Polymorph
	[83098]	= 15,	-- Improved Mana Gem
	[84585]	= 15,	-- Slaughter
	[86662]	= 15,	-- Rude Interruption
	[87160]	= 6,	-- Mind Melt
	[87178]	= 12,	-- Mind Spike
	[87717]	= 0,	-- Tranquil Mind
	[89792]	= 0.2,	-- Flee
	[5740]	= 8,	-- Rain of Fire
	[17735]	= 5,	-- Suffering
	[19975]	= 27,	-- Entangling Roots
	[33745]	= 15,	-- Lacerate
	[63087]	= 5,	-- Raptor Strike
	[79437]	= 8,	-- Soulburn: Healthstone
	[80951]	= 10,	-- Pulverize
	[85387]	= 2,	-- Aftermath
	[86663]	= 30,	-- Rude Interruption
	[87194]	= 4,	-- Paralysis
	[93622]	= 5,	-- Berserk
	[10]	= 8,	-- Blizzard
	[8034]	= 8,	-- Frostbrand Attack
	[73682]	= 5,	-- Unleash Frost
	[5225]	= 0,	-- Track Humanoids
	[12968]	= 15,	-- Flurry
	[26679]	= 6,	-- Deadly Throw
	[48505]	= 10,	-- Starfall
	[48719]	= 600,	-- Water Breathing
	[60970]	= 0.1,	-- Heroic Fury
	[61391]	= 6,	-- Typhoon
	[61882]	= 8,	-- Earthquake
	[77764]	= 6,	-- Stampeding Roar
	[79462]	= 20,	-- Demon Soul: Felguard
	[81192]	= 3,	-- Lunar Shower
	[81261]	= 10,	-- Solar Beam
	[81281]	= 2,	-- Fungal Growth
	[84617]	= 15,	-- Revealing Strike
	[84745]	= 15,	-- Shallow Insight
	[84746]	= 15,	-- Moderate Insight
	[84747]	= 15,	-- Deep Insight
	[85539]	= 0,	-- Jinx
	[86105]	= 3,	-- Jinx: Curse of the Elements
	[86759]	= 3,	-- Silenced - Improved Kick
	[93400]	= 8,	-- Shooting Stars
	[93402]	= 12,	-- Sunfire
	[93986]	= 3,	-- Aura of Foreboding
	[746]	= 6,	-- First Aid
	[1022]	= 10,	-- Hand of Protection
	[20050]	= 15,	-- Conviction
	[27243]	= 18,	-- Seed of Corruption
	[76780]	= 50,	-- Bind Elemental
	[79062]	= 3600,	-- Blessing of Kings
	[79464]	= 15,	-- Demon Soul: Voidwalker
	[81661]	= 15,	-- Evangelism
	[81700]	= 18,	-- Archangel
	[80325]	= 0,	-- Camouflage
	[81301]	= 12,	-- Glyph of Spirit Tap
	[87204]	= 3,	-- Sin and Punishment
	[51701]	= 0,	-- Honor Among Thieves
	[81021]	= 10,	-- Stampede
	[81130]	= 30,	-- Scarlet Fever
	[90806]	= 9,	-- Executioner
	[28271]	= 50,	-- Polymorph (turtle)
	[28272]	= 50,	-- Polymorph (pig)
	[61305]	= 50,	-- Polymorph (cat)
}



--Durations that don't match PvE durations.
--http://www.wowwiki.com/Diminishing_returns
NP.auraInfoPvP = {
	[339]	= 8, 	-- Entangling Roots	
	[2637]	= 8, 	-- Hibernate (18657)
	[3355]	= 8, 	-- Freezing Trap Effect
	[61721] = 8, 	-- Polymorph (Rabbit)
	[118]	= 8,	-- Polymorph
	[28271]	= 8,	-- Polymorph (turtle)
	[28272]	= 8,	-- Polymorph (pig)
	[61305]	= 8,	-- Polymorph (cat)
	[20066] = 6, 	-- Repentance
	[10326] = 8, 	-- Turn Evil
	[605]	= 8, 	-- Mind Control
	[6770]	= 8, 	-- Sap
	[51514] = 8, 	-- Hex 
	[6358]	= 8, 	-- Seduction
	[1715]	= 8, 	-- Hamstring
	[770]	= 40, 	-- Faerie Fire
	[16857] = 40, 	-- Faerie Fire (Feral)
	[710]	= 6,	-- Banish
	[5782]	= 8,	-- Fear
	[1130]	= 120,	-- Hunter's Mark
	[1490]	= 120,	-- Curse of the Elements
	[19386]	= 6,	-- Wyvern Sting
	[9484]	= 8,	-- Shackle Undead

}

NP.lockouts = {
	[2139]	= 7, -- Counterspell
	[26679]	= 3, -- Deadly Throw
	[1766]	= 5, -- Kick
	[47528]	= 4, -- Mind Freeze
	[6552]	= 4, -- Pummel
	[96231]	= 4, -- Rebuke
	[80965]	= 4, -- Skull Bash (Cat)
	[93985]	= 4, -- Skull Bash (Cat)
	[80964]	= 4, -- Skill Bash (Bear)
	[19647]	= 6, -- Spell Lock
	[31935]	= 3, -- Avenger's Shield
	[26090]	= 2, -- Pummel (Gorilla)
	[57994]	= 2, -- Wind Shear
}

E:RegisterModule(NP:GetName())