local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');

local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

for i=10, 40, 15 do
	UF['Construct_Raid'..i..'Frames'] = function (self, unitGroup)
		self:RegisterForClicks("AnyUp")
		self:SetScript('OnEnter', UnitFrame_OnEnter)
		self:SetScript('OnLeave', UnitFrame_OnLeave)	
		
		self.menu = UF.SpawnMenu

		self.Health = UF:Construct_HealthBar(self, true, true, 'RIGHT')
		
		self.Power = UF:Construct_PowerBar(self, true, true, 'LEFT', false)
		self.Power.frequentUpdates = false;
		
		self.Name = UF:Construct_NameText(self)
		self.Buffs = UF:Construct_Buffs(self)
		self.Debuffs = UF:Construct_Debuffs(self)
		self.AuraWatch = UF:Construct_AuraWatch(self)
		self.RaidDebuffs = UF:Construct_RaidDebuffs(self)
		self.DebuffHighlight = UF:Construct_DebuffHighlight(self)
		self.ResurrectIcon = UF:Construct_ResurectionIcon(self)
		self.LFDRole = UF:Construct_RoleIcon(self)
		
		self.TargetGlow = UF:Construct_TargetGlow(self)
		table.insert(self.__elements, UF.UpdateThreat)
		table.insert(self.__elements, UF.UpdateTargetGlow)
		self:RegisterEvent('PLAYER_TARGET_CHANGED', function(...) UF.UpdateThreat(...); UF.UpdateTargetGlow(...) end)
		self:RegisterEvent('PLAYER_ENTERING_WORLD', UF.UpdateTargetGlow)
		self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', UF.UpdateThreat)
		self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', UF.UpdateThreat)		
		
		self.RaidIcon = UF:Construct_RaidIcon(self)
		self.ReadyCheck = UF:Construct_ReadyCheckIcon(self)	
		self.HealPrediction = UF:Construct_HealComm(self)
		
		UF['Update_Raid'..i..'Frames'](UF, self, E.db['unitframe']['units']['raid'..i])
		UF:Update_StatusBars()
		UF:Update_FontStrings()	
		
		return self
	end

	UF['Raid'..i..'SmartVisibility'] = function (self, event)	
		if not self.db or not self.SetAttribute or (self.db and not self.db.enable) or (UF.db and not UF.db.smartRaidFilter) or self.isForced then return; end
		local inInstance, instanceType = IsInInstance()
		local _, _, _, _, maxPlayers, _, _ = GetInstanceInfo()
		if event == "PLAYER_REGEN_ENABLED" then self:UnregisterEvent("PLAYER_REGEN_ENABLED") end
		if not InCombatLockdown() then		
			if inInstance and instanceType == "raid" and maxPlayers == i then
				RegisterAttributeDriver(self, 'state-visibility', 'show')
			elseif inInstance and instanceType == "raid" then
				RegisterAttributeDriver(self, 'state-visibility', 'hide')
			elseif self.db.visibility then
				UF:ChangeVisibility(self, 'custom '..self.db.visibility)
			end
		else
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
			return
		end
	end

	UF['Update_Raid'..i..'Header'] = function (self, header, db)
		if not header.isForced then
			header:Hide()
			header:SetAttribute('oUF-initialConfigFunction', ([[self:SetWidth(%d); self:SetHeight(%d); self:SetFrameLevel(5)]]):format(db.width, db.height))
			header:SetAttribute('startingIndex', 1)
		end
		
		header.db = db
		
		--User Error Check
		if UF['badHeaderPoints'][db.point] == db.columnAnchorPoint then
			db.columnAnchorPoint = db.point
			E:Print(L['You cannot set the Group Point and Column Point so they are opposite of each other.'])
		end	
		
		
		if not header.isForced then	
			self:ChangeVisibility(header, 'custom '..db.visibility)
		end
		
		if db.groupBy == 'CLASS' then
			header:SetAttribute("groupingOrder", "DEATHKNIGHT,DRUID,HUNTER,MAGE,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR")
			header:SetAttribute('sortMethod', 'NAME')
		elseif db.groupBy == 'ROLE' then
			header:SetAttribute("groupingOrder", "MAINTANK,MAINASSIST,1,2,3,4,5,6,7,8")
			header:SetAttribute('sortMethod', 'NAME')
		else
			header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
			header:SetAttribute('sortMethod', 'INDEX')
		end
		
		header:SetAttribute("groupBy", db.groupBy)
		
		if not header.isForced then
			header:SetAttribute("showParty", db.showParty)
			header:SetAttribute("showRaid", db.showRaid)
			header:SetAttribute("showSolo", db.showSolo)
			header:SetAttribute("showPlayer", db.showPlayer)
		end

		header:SetAttribute("maxColumns", db.maxColumns)
		header:SetAttribute("unitsPerColumn", db.unitsPerColumn)
		
		header:SetAttribute('columnSpacing', db.columnSpacing)
		header:SetAttribute("xOffset", db.xOffset)	
		header:SetAttribute("yOffset", db.yOffset)

		
		header:SetAttribute('columnAnchorPoint', db.columnAnchorPoint)
		
		UF:ClearChildPoints(header:GetChildren())
		
		header:SetAttribute('point', db.point)

		if not header.positioned then
			header:ClearAllPoints()
			header:Point("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", 4, 195)	
			E:CreateMover(header, header:GetName()..'Mover', 'Raid 1-'..i..' Frames')
			
			header:SetAttribute('minHeight', header.dirtyHeight)
			header:SetAttribute('minWidth', header.dirtyWidth)
			
			header:RegisterEvent("PLAYER_ENTERING_WORLD")
			header:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			header:HookScript("OnEvent", UF['Raid'..i..'SmartVisibility'])
			header.positioned = true;
		end
			
		UF['Raid'..i..'SmartVisibility'](header)
	end

	UF['Update_Raid'..i..'Frames'] = function (self, frame, db)
		frame.db = db
		local BORDER = E:Scale(2)
		local SPACING = E:Scale(1)
		local UNIT_WIDTH = db.width
		local UNIT_HEIGHT = db.height
		
		local USE_POWERBAR = db.power.enable
		local USE_MINI_POWERBAR = db.power.width ~= 'fill' and USE_POWERBAR
		local USE_POWERBAR_OFFSET = db.power.offset ~= 0 and USE_POWERBAR
		local POWERBAR_OFFSET = db.power.offset
		local POWERBAR_HEIGHT = db.power.height
		local POWERBAR_WIDTH = db.width - (BORDER*2)
		
		frame.db = db
		frame.colors = ElvUF.colors
		if not InCombatLockdown() then
			frame:Size(UNIT_WIDTH, UNIT_HEIGHT)
		end
		frame.Range = {insideAlpha = 1, outsideAlpha = E.db.unitframe.OORAlpha}
		
		--Adjust some variables
		do
			if not USE_POWERBAR then
				POWERBAR_HEIGHT = 0
			end	
		
			if USE_MINI_POWERBAR then
				POWERBAR_WIDTH = POWERBAR_WIDTH / 2
			end
		end
		
		--Health
		do
			local health = frame.Health
			health.Smooth = self.db.smoothbars
			health.frequentUpdates = db.health.frequentUpdates
			
			--Text
			if db.health.text then
				health.value:Show()
			else
				health.value:Hide()
			end
			
			--Position this even if disabled because resurrection icon depends on the position
			local x, y = self:GetPositionOffset(db.health.position)
			health.value:ClearAllPoints()
			health.value:Point(db.health.position, health, db.health.position, x, y)
			
			--Colors
			health.colorSmooth = nil
			health.colorHealth = nil
			health.colorClass = nil
			health.colorReaction = nil
			if self.db['colors'].healthclass ~= true then
				if self.db['colors'].colorhealthbyvalue == true then
					health.colorSmooth = true
				else
					health.colorHealth = true
				end		
			else
				health.colorClass = true
				health.colorReaction = true
			end	
			
			--Position
			health:ClearAllPoints()
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -BORDER, -BORDER)
			if USE_POWERBAR_OFFSET then			
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER+POWERBAR_OFFSET, BORDER+POWERBAR_OFFSET)
			elseif USE_MINI_POWERBAR then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + (POWERBAR_HEIGHT/2))
			else
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + POWERBAR_HEIGHT)
			end
			
			health:SetOrientation(db.health.orientation)
		end
		
		--Name
		do
			local name = frame.Name
			if db.name.enable then
				name:Show()
				
				if not db.power.hideonnpc then
					local x, y = self:GetPositionOffset(db.name.position)
					name:ClearAllPoints()
					name:Point(db.name.position, frame.Health, db.name.position, x, y)				
				end
				
				if db.name.length == "SHORT" then
					frame:Tag(name, '[Elv:getnamecolor][Elv:nameshort]')
				elseif db.name.length == "MEDIUM" then
					frame:Tag(name, '[Elv:getnamecolor][Elv:namemedium]')
				elseif db.name.length == "LONG" then
					frame:Tag(name, '[Elv:getnamecolor][Elv:namelong]')
				else
					frame:Tag(name, '[Elv:diffcolor][level] [Elv:getnamecolor][Elv:namelong]')
				end			
			else
				name:Hide()
			end
		end	
		
		--Power
		do
			local power = frame.Power
			if USE_POWERBAR then
				frame:EnableElement('Power')
				power:Show()		
				power.Smooth = self.db.smoothbars
				
				--Text
				if db.power.text then
					power.value:Show()
					
					local x, y = self:GetPositionOffset(db.power.position)
					power.value:ClearAllPoints()
					power.value:Point(db.power.position, frame.Health, db.power.position, x, y)					
				else
					power.value:Hide()
				end
				
				--Colors
				power.colorClass = nil
				power.colorReaction = nil	
				power.colorPower = nil
				if self.db['colors'].powerclass then
					power.colorClass = true
					power.colorReaction = true
				else
					power.colorPower = true
				end		
				
				--Position
				power:ClearAllPoints()
				if USE_POWERBAR_OFFSET then
					power:Point("TOPLEFT", frame.Health, "TOPLEFT", -POWERBAR_OFFSET, -POWERBAR_OFFSET)
					power:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -POWERBAR_OFFSET, -POWERBAR_OFFSET)
					power:SetFrameStrata("LOW")
					power:SetFrameLevel(2)
				elseif USE_MINI_POWERBAR then
					power:Width(POWERBAR_WIDTH - BORDER*2)
					power:Height(POWERBAR_HEIGHT - BORDER*2)
					power:Point("LEFT", frame, "BOTTOMLEFT", (BORDER*2 + 4), BORDER + (POWERBAR_HEIGHT/2))
					power:SetFrameStrata("MEDIUM")
					power:SetFrameLevel(frame:GetFrameLevel() + 3)
				else
					power:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", BORDER, -(BORDER + SPACING))
					power:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(BORDER), BORDER)
				end
			else
				frame:DisableElement('Power')
				power:Hide()
				power.value:Hide()
			end
			
		end
		
		--Target Glow
		do
			local tGlow = frame.TargetGlow
			tGlow:ClearAllPoints()
			tGlow:Point("TOPLEFT", -4, 4)
			tGlow:Point("TOPRIGHT", 4, 4)
			
			if USE_MINI_POWERBAR then
				tGlow:Point("BOTTOMLEFT", -4, -4 + (POWERBAR_HEIGHT/2))
				tGlow:Point("BOTTOMRIGHT", 4, -4 + (POWERBAR_HEIGHT/2))		
			else
				tGlow:Point("BOTTOMLEFT", -4, -4)
				tGlow:Point("BOTTOMRIGHT", 4, -4)
			end
			
			if USE_POWERBAR_OFFSET then
				tGlow:Point("TOPLEFT", -4+POWERBAR_OFFSET, 4)
				tGlow:Point("TOPRIGHT", 4, 4)
				tGlow:Point("BOTTOMLEFT", -4+POWERBAR_OFFSET, -4+POWERBAR_OFFSET)
				tGlow:Point("BOTTOMRIGHT", 4, -4+POWERBAR_OFFSET)				
			end				
		end			

		--Auras Disable/Enable
		--Only do if both debuffs and buffs aren't being used.
		do
			if db.debuffs.enable or db.buffs.enable then
				frame:EnableElement('Aura')
			else
				frame:DisableElement('Aura')		
			end
			
			frame.Buffs:ClearAllPoints()
			frame.Debuffs:ClearAllPoints()
		end
		
		--Buffs
		do
			local buffs = frame.Buffs
			local rows = db.buffs.numrows
			
			if USE_POWERBAR_OFFSET then
				buffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
			else
				buffs:SetWidth(UNIT_WIDTH)
			end

			buffs.forceShow = frame:GetParent().forceShowAuras
			buffs.num = db.buffs.perrow * rows
			buffs.size = db.buffs.sizeOverride ~= 0 and db.buffs.sizeOverride or ((((buffs:GetWidth() - (buffs.spacing*(buffs.num/rows - 1))) / buffs.num)) * rows)
			
			if db.buffs.sizeOverride and db.buffs.sizeOverride > 0 then
				buffs:SetWidth(db.buffs.perrow * db.buffs.sizeOverride)
			end
			
			local x, y = self:GetAuraOffset(db.buffs.initialAnchor, db.buffs.anchorPoint)
			local attachTo = self:GetAuraAnchorFrame(frame, db.buffs.attachTo)

			buffs:Point(db.buffs.initialAnchor, attachTo, db.buffs.anchorPoint, x, y)
			buffs:Height(buffs.size * rows)
			buffs.initialAnchor = db.buffs.initialAnchor
			buffs["growth-y"] = db.buffs['growth-y']
			buffs["growth-x"] = db.buffs['growth-x']

			if db.buffs.enable then			
				buffs:Show()
			else
				buffs:Hide()
			end
		end
		
		--Debuffs
		do
			local debuffs = frame.Debuffs
			local rows = db.debuffs.numrows
			
			if USE_POWERBAR_OFFSET then
				debuffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
			else
				debuffs:SetWidth(UNIT_WIDTH)
			end

			debuffs.forceShow = frame:GetParent().forceShowAuras
			debuffs.num = db.debuffs.perrow * rows
			debuffs.size = db.debuffs.sizeOverride ~= 0 and db.debuffs.sizeOverride or ((((debuffs:GetWidth() - (debuffs.spacing*(debuffs.num/rows - 1))) / debuffs.num)) * rows)
			
			if db.debuffs.sizeOverride and db.debuffs.sizeOverride > 0 then
				debuffs:SetWidth(db.debuffs.perrow * db.debuffs.sizeOverride)
			end
			
			local x, y = self:GetAuraOffset(db.debuffs.initialAnchor, db.debuffs.anchorPoint)
			local attachTo = self:GetAuraAnchorFrame(frame, db.debuffs.attachTo, db.buffs.attachTo == 'DEBUFFS' and db.debuffs.attachTo == 'BUFFS')

			debuffs:Point(db.debuffs.initialAnchor, attachTo, db.debuffs.anchorPoint, x, y)
			debuffs:Height(debuffs.size * rows)
			debuffs.initialAnchor = db.debuffs.initialAnchor
			debuffs["growth-y"] = db.debuffs['growth-y']
			debuffs["growth-x"] = db.debuffs['growth-x']

			if db.debuffs.enable then			
				debuffs:Show()
			else
				debuffs:Hide()
			end
		end	
		
		--RaidDebuffs
		do
			local rdebuffs = frame.RaidDebuffs
			if db.rdebuffs.enable then
				frame:EnableElement('RaidDebuffs')				

				rdebuffs:Size(db.rdebuffs.size)
				
				rdebuffs.count:FontTemplate(nil, db.rdebuffs.fontsize, 'OUTLINE')
				rdebuffs.time:FontTemplate(nil, db.rdebuffs.fontsize, 'OUTLINE')
			else
				frame:DisableElement('RaidDebuffs')
				rdebuffs:Hide()				
			end
		end

		--Debuff Highlight
		do
			local dbh = frame.DebuffHighlight
			if E.db.unitframe.debuffHighlighting then
				frame:EnableElement('DebuffHighlight')
			else
				frame:DisableElement('DebuffHighlight')
			end
		end

		--Role Icon
		do
			local role = frame.LFDRole
			if db.roleIcon.enable then
				frame:EnableElement('LFDRole')				
				
				local x, y = self:GetPositionOffset(db.roleIcon.position, 1)
				role:ClearAllPoints()
				role:Point(db.roleIcon.position, frame.Health, db.roleIcon.position, x, y)
			else
				frame:DisableElement('LFDRole')	
				role:Hide()
			end
		end
		
		--OverHealing
		do
			local healPrediction = frame.HealPrediction
			
			if db.healPrediction then
				frame:EnableElement('HealPrediction')
				
				healPrediction.myBar:ClearAllPoints()
				healPrediction.myBar:SetOrientation(db.health.orientation)
				healPrediction.otherBar:ClearAllPoints()
				healPrediction.otherBar:SetOrientation(db.health.orientation)
				
				if db.health.orientation == 'HORIZONTAL' then
					healPrediction.myBar:Width(db.width - (BORDER*2))
					healPrediction.myBar:SetPoint('BOTTOMLEFT', frame.Health:GetStatusBarTexture(), 'BOTTOMRIGHT')
					healPrediction.myBar:SetPoint('TOPLEFT', frame.Health:GetStatusBarTexture(), 'TOPRIGHT')	

					healPrediction.otherBar:SetPoint('TOPLEFT', healPrediction.myBar:GetStatusBarTexture(), 'TOPRIGHT')	
					healPrediction.otherBar:SetPoint('BOTTOMLEFT', healPrediction.myBar:GetStatusBarTexture(), 'BOTTOMRIGHT')	
					healPrediction.otherBar:Width(db.width - (BORDER*2))
				else
					healPrediction.myBar:Height(db.height - (BORDER*2))
					healPrediction.myBar:SetPoint('BOTTOMLEFT', frame.Health:GetStatusBarTexture(), 'TOPLEFT')
					healPrediction.myBar:SetPoint('BOTTOMRIGHT', frame.Health:GetStatusBarTexture(), 'TOPRIGHT')				

					healPrediction.otherBar:SetPoint('BOTTOMLEFT', healPrediction.myBar:GetStatusBarTexture(), 'TOPLEFT')
					healPrediction.otherBar:SetPoint('BOTTOMRIGHT', healPrediction.myBar:GetStatusBarTexture(), 'TOPRIGHT')				
					healPrediction.otherBar:Height(db.height - (BORDER*2))	
				end
				
			else
				frame:DisableElement('HealPrediction')	
			end
		end		
		
		UF:UpdateAuraWatch(frame)
		
		frame:EnableElement('ReadyCheck')		
		frame:UpdateAllElements()
	end

	UF['headerstoload']['raid'..i] = true
end