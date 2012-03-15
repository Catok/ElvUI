local E, L, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, ProfileDB, GlobalDB
local S = E:GetModule('Skins')

local function LoadSkin()
	if E.global.skins.blizzard.enable ~= true or E.global.skins.blizzard.bgmap ~= true then return end
	
	BattlefieldMinimapCorner:Kill()
	BattlefieldMinimapBackground:Kill()
	BattlefieldMinimapTab:Kill()
	BattlefieldMinimapTabLeft:Kill()
	BattlefieldMinimapTabMiddle:Kill()
	BattlefieldMinimapTabRight:Kill()
	
	BattlefieldMinimap:CreateBackdrop('Default')
	BattlefieldMinimap.backdrop:Point('BOTTOMRIGHT', -4, 2)
	
	BattlefieldMinimapCloseButton:ClearAllPoints()
	BattlefieldMinimapCloseButton:SetPoint("TOPRIGHT", -4, 0)	
	S:HandleCloseButton(BattlefieldMinimapCloseButton)
	BattlefieldMinimapCloseButton:SetFrameLevel(8)	
	BattlefieldMinimapCloseButton.text:ClearAllPoints()
	BattlefieldMinimapCloseButton.text:SetPoint('CENTER', BattlefieldMinimapCloseButton, 'CENTER', 1, 1)
	
	BattlefieldMinimap:EnableMouse(true)
	BattlefieldMinimap:SetMovable(true)
	
	BattlefieldMinimap:SetScript("OnMouseUp", function(self, btn)
		if btn == "LeftButton" then
			BattlefieldMinimapTab:StopMovingOrSizing()
			BattlefieldMinimapTab:SetUserPlaced(true)
			if OpacityFrame:IsShown() then OpacityFrame:Hide() end -- seem to be a bug with default ui in 4.0, we hide it on next click
		elseif btn == "RightButton" then
			ToggleDropDownMenu(1, nil, BattlefieldMinimapTabDropDown, self:GetName(), 0, -4)
			if OpacityFrame:IsShown() then OpacityFrame:Hide() end -- seem to be a bug with default ui in 4.0, we hide it on next click
		end
	end)

	BattlefieldMinimap:SetScript("OnMouseDown", function(self, btn)
		if btn == "LeftButton" then
			if BattlefieldMinimapOptions and BattlefieldMinimapOptions.locked then
				return
			else
				BattlefieldMinimapTab:StartMoving()
			end
		end
	end)	
	
	hooksecurefunc('BattlefieldMinimap_UpdateOpacity', function(opacity)
		local opacity = opacity or OpacityFrameSlider:GetValue();
		local alpha = 1.0 - BattlefieldMinimapOptions.opacity;
		BattlefieldMinimap.backdrop:SetAlpha(alpha)
	end)
	
	
	BattlefieldMinimap:HookScript('OnEnter', function()
		BattlefieldMinimap_UpdateOpacity(0)
	end)
	
	BattlefieldMinimap:HookScript('OnLeave', function()
		BattlefieldMinimap_UpdateOpacity(OpacityFrameSlider:GetValue())
	end)
	
	BattlefieldMinimapCloseButton:HookScript('OnEnter', function()
		BattlefieldMinimap_UpdateOpacity(0)
	end)
	
	BattlefieldMinimapCloseButton:HookScript('OnLeave', function()
		BattlefieldMinimap_UpdateOpacity(OpacityFrameSlider:GetValue())
	end)	
end

S:RegisterSkin("Blizzard_BattlefieldMinimap", LoadSkin)