local E, L, DF = unpack(select(2, ...)); --Engine
local S = E:GetModule('Skins')

local function LoadSkin()
	if E.db.skins.blizzard.enable ~= true or E.db.skins.blizzard.tradeskill ~= true then return end
	TradeSkillFrame:StripTextures(true)
	TradeSkillListScrollFrame:StripTextures()
	TradeSkillDetailScrollFrame:StripTextures()
	TradeSkillFrameInset:StripTextures()
	TradeSkillExpandButtonFrame:StripTextures()
	TradeSkillDetailScrollChildFrame:StripTextures()
	
	TradeSkillFrame:SetTemplate("Transparent")
	TradeSkillFrame:CreateShadow("Default")
	TradeSkillFrame:Height(TradeSkillFrame:GetHeight() + 12)
	TradeSkillRankFrame:StripTextures()
	TradeSkillRankFrame:CreateBackdrop("Default")
	TradeSkillRankFrame:SetStatusBarTexture(E["media"].normTex)
	
	S:HandleButton(TradeSkillCreateButton, true)
	S:HandleButton(TradeSkillCancelButton, true)
	S:HandleButton(TradeSkillFilterButton, true)
	S:HandleButton(TradeSkillCreateAllButton, true)
	S:HandleButton(TradeSkillViewGuildCraftersButton, true)
	
	S:HandleScrollBar(TradeSkillListScrollFrameScrollBar)
	S:HandleScrollBar(TradeSkillDetailScrollFrameScrollBar)	
	
	TradeSkillLinkButton:GetNormalTexture():SetTexCoord(0.25, 0.7, 0.37, 0.75)
	TradeSkillLinkButton:GetPushedTexture():SetTexCoord(0.25, 0.7, 0.45, 0.8)
	TradeSkillLinkButton:GetHighlightTexture():Kill()
	TradeSkillLinkButton:CreateBackdrop("Default")
	TradeSkillLinkButton:Size(17, 14)
	TradeSkillLinkButton:Point("LEFT", TradeSkillLinkFrame, "LEFT", 5, -1)
	S:HandleEditBox(TradeSkillFrameSearchBox)
	S:HandleEditBox(TradeSkillInputBox)
	S:HandleNextPrevButton(TradeSkillDecrementButton)
	S:HandleNextPrevButton(TradeSkillIncrementButton)
	TradeSkillIncrementButton:Point("RIGHT", TradeSkillCreateButton, "LEFT", -13, 0)
	
	S:HandleCloseButton(TradeSkillFrameCloseButton)
	
	local once = false
	hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
		TradeSkillSkillIcon:StyleButton()
		if TradeSkillSkillIcon:GetNormalTexture() then
			TradeSkillSkillIcon:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
			TradeSkillSkillIcon:GetNormalTexture():ClearAllPoints()
			TradeSkillSkillIcon:GetNormalTexture():Point("TOPLEFT", 2, -2)
			TradeSkillSkillIcon:GetNormalTexture():Point("BOTTOMRIGHT", -2, 2)
		end
		TradeSkillSkillIcon:SetTemplate("Default")

		for i=1, MAX_TRADE_SKILL_REAGENTS do
			local button = _G["TradeSkillReagent"..i]
			local icon = _G["TradeSkillReagent"..i.."IconTexture"]
			local count = _G["TradeSkillReagent"..i.."Count"]
			
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer("OVERLAY")
			if not icon.backdrop then
				icon.backdrop = CreateFrame("Frame", nil, button)
				icon.backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
				icon.backdrop:SetTemplate("Default")
				icon.backdrop:Point("TOPLEFT", icon, "TOPLEFT", -2, 2)
				icon.backdrop:Point("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
			end
			
			icon:SetParent(icon.backdrop)
			count:SetParent(icon.backdrop)
			count:SetDrawLayer("OVERLAY")
			
			if i > 2 and once == false then
				local point, anchoredto, point2, x, y = button:GetPoint()
				button:ClearAllPoints()
				button:Point(point, anchoredto, point2, x, y - 3)
				once = true
			end
			
			_G["TradeSkillReagent"..i.."NameFrame"]:Kill()
		end
	end)
	
	
	--Guild Crafters
	TradeSkillGuildFrame:StripTextures()
	TradeSkillGuildFrame:SetTemplate("Transparent")
	TradeSkillGuildFrame:Point("BOTTOMLEFT", TradeSkillFrame, "BOTTOMRIGHT", 3, 19)
	TradeSkillGuildFrameContainer:StripTextures()
	TradeSkillGuildFrameContainer:SetTemplate("Default")
	S:HandleCloseButton(TradeSkillGuildFrameCloseButton)
end

S:RegisterSkin("Blizzard_TradeSkillUI", LoadSkin)