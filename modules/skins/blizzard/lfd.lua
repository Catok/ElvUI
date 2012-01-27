local E, L, DF = unpack(select(2, ...)); --Engine
local S = E:GetModule('Skins')

local function LoadSkin()
	if E.db.skins.blizzard.enable ~= true or E.db.skins.blizzard.lfd ~= true then return end
	local StripAllTextures = {
		"LFDParentFrame",
		"LFDQueueFrame",
		"LFDQueueFrameSpecific",
		"LFDQueueFrameRandom",
		"LFDQueueFrameRandomScrollFrame",
		"LFDQueueFrameCapBar",
	}

	if E:IsPTRVersion() then
		tinsert(StripAllTextures, 'LFGDungeonReadyDialog')
	else
		tinsert(StripAllTextures, 'LFDDungeonReadyDialog')
	end

	local KillTextures = {
		"LFDQueueFrameBackground",
		"LFDParentFrameInset",
		"LFDParentFrameEyeFrame",
		"LFDQueueFrameRoleButtonTankBackground",
		"LFDQueueFrameRoleButtonHealerBackground",
		"LFDQueueFrameRoleButtonDPSBackground",
	}

	if E:IsPTRVersion() then
		LFGDungeonReadyDialogBackground:Kill()
		S:HandleButton(LFGDungeonReadyDialogEnterDungeonButton)
		S:HandleButton(LFGDungeonReadyDialogLeaveQueueButton)
	else
		LFDDungeonReadyDialogBackground:Kill()
	end

	local buttons = {
		"LFDQueueFrameFindGroupButton",
		"LFDQueueFrameCancelButton",
		"LFDQueueFramePartyBackfillBackfillButton",
		"LFDQueueFramePartyBackfillNoBackfillButton",
	}

	local checkButtons = {
		"LFDQueueFrameRoleButtonTank",
		"LFDQueueFrameRoleButtonHealer",
		"LFDQueueFrameRoleButtonDPS",
		"LFDQueueFrameRoleButtonLeader",
	}

	for _, object in pairs(checkButtons) do
		_G[object].checkButton:SetFrameLevel(_G[object].checkButton:GetFrameLevel() + 2)
		S:HandleCheckBox(_G[object].checkButton)
	end

	hooksecurefunc("LFDQueueFrameRandom_UpdateFrame", function()
		local dungeonID = LFDQueueFrame.type
		if type(dungeonID) == "string" then return end
		local _, _, _, _, _, numRewards = GetLFGDungeonRewards(dungeonID)

		for i=1, LFD_MAX_REWARDS do
			local button = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i]
			local icon = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i.."IconTexture"]
			local count = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i.."Count"]
			local role1 = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i.."RoleIcon1"]
			local role2 = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i.."RoleIcon2"]
			local role3 = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i.."RoleIcon3"]

			if button then
				local __texture = _G[button:GetName().."IconTexture"]:GetTexture()
				button:StripTextures()
				icon:SetTexture(__texture)
				icon:SetTexCoord(unpack(E.TexCoords))
				icon:Point("TOPLEFT", 2, -2)
				icon:SetDrawLayer("OVERLAY")
				count:SetDrawLayer("OVERLAY")
				if not button.backdrop then
					button:CreateBackdrop("Default")
					button.backdrop:Point("TOPLEFT", icon, "TOPLEFT", -2, 2)
					button.backdrop:Point("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
					icon:SetParent(button.backdrop)
					icon.SetPoint = E.noop

					if count then
						count:SetParent(button.backdrop)
					end
					if role1 then
						role1:SetParent(button.backdrop)
					end
					if role2 then
						role2:SetParent(button.backdrop)
					end
					if role3 then
						role3:SetParent(button.backdrop)
					end
				end
			end
		end
	end)

	hooksecurefunc("LFDQueueFrameSpecificListButton_SetDungeon", function(button, dungeonID, mode, submode)
		for _, object in pairs(checkButtons) do
			local button = _G[object]
			if not ( button.checkButton:GetChecked() ) then
				button.checkButton:SetDisabledTexture(nil)
			else
				button.checkButton:SetDisabledTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
			end
		end

		local oldTex = button.enableButton:GetDisabledCheckedTexture():GetTexture()
		if not button.enableButton:GetChecked() then
			button.enableButton:SetDisabledTexture(nil)
		else
			button.enableButton:SetDisabledTexture(oldTex)
		end
	end)

	for _, object in pairs(StripAllTextures) do
		_G[object]:StripTextures()
	end

	for _, texture in pairs(KillTextures) do
		_G[texture]:Kill()
	end

	for i = 1, #buttons do
		_G[buttons[i]]:StripTextures()
		S:HandleButton(_G[buttons[i]])
	end	

	for i=1, NUM_LFD_CHOICE_BUTTONS do
		S:HandleCheckBox(_G["LFDQueueFrameSpecificListButton"..i.."EnableButton"])
	end

	LFDQueueFrameCapBar:SetPoint("LEFT", 40, 0)

	if not E:IsPTRVersion() then
		LFDDungeonReadyDialog:SetTemplate("Transparent")
		LFDDungeonReadyDialog:CreateShadow("Default")
	else
		LFGDungeonReadyDialog:SetTemplate("Transparent")
		LFGDungeonReadyDialog:CreateShadow("Default")
	end

	LFDQueueFrameSpecificListScrollFrame:StripTextures()
	LFDQueueFrameSpecificListScrollFrame:Height(LFDQueueFrameSpecificListScrollFrame:GetHeight() - 8)
	LFDParentFrame:CreateBackdrop("Transparent")
	LFDParentFrame.backdrop:Point( "TOPLEFT", LFDParentFrame, "TOPLEFT")
	LFDParentFrame.backdrop:Point( "BOTTOMRIGHT", LFDParentFrame, "BOTTOMRIGHT")
	S:HandleCloseButton(LFDParentFrameCloseButton,LFDParentFrame)

	if not E:IsPTRVersion() then
		S:HandleCloseButton(LFDDungeonReadyDialogCloseButton,LFDDungeonReadyDialog)
	else
		S:HandleCloseButton(LFGDungeonReadyDialogCloseButton, LFGDungeonReadyDialog)
	end

	S:HandleDropDownBox(LFDQueueFrameTypeDropDown, 300)
	LFDQueueFrameTypeDropDown:Point("RIGHT",-10,0)
	LFDQueueFrameCapBar:CreateBackdrop("Transparent")
	LFDQueueFrameCapBar.backdrop:Point( "TOPLEFT", LFDQueueFrameCapBar, "TOPLEFT", 1, -1)
	LFDQueueFrameCapBar.backdrop:Point( "BOTTOMRIGHT", LFDQueueFrameCapBar, "BOTTOMRIGHT", -1, 1 )
	LFDQueueFrameCapBarProgress:SetTexture(E["media"].normTex)
	LFDQueueFrameCapBarCap1:SetTexture(E["media"].normTex)
	LFDQueueFrameCapBarCap2:SetTexture(E["media"].normTex)
	S:HandleScrollBar(LFDQueueFrameSpecificListScrollFrameScrollBar)
	LFGDungeonReadyPopup:SetTemplate("Default")
	LFGDungeonReadyPopup:CreateShadow("Default")
	LFGDungeonReadyDialog.SetBackdrop = E.noop
	LFGDungeonReadyDialog.filigree:SetAlpha(0)
	LFGDungeonReadyDialog.bottomArt:SetAlpha(0)
	S:HandleButton(LFGDungeonReadyDialogLeaveQueueButton)
	S:HandleButton(LFGDungeonReadyDialogEnterDungeonButton)
	S:HandleCloseButton(LFGDungeonReadyDialogCloseButton)
	LFGDungeonReadyStatus:SetTemplate("Default")
	S:HandleCloseButton(LFGDungeonReadyStatusCloseButton)
	end

S:RegisterSkin('ElvUI', LoadSkin)