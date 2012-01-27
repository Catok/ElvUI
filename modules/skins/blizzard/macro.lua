local E, L, DF = unpack(select(2, ...)); --Engine
local S = E:GetModule('Skins')

local function LoadSkin()
	if E.db.skins.blizzard.enable ~= true or E.db.skins.blizzard.macro ~= true then return end
	S:HandleCloseButton(MacroFrameCloseButton)
	S:HandleScrollBar(MacroButtonScrollFrameScrollBar, 5)
	S:HandleScrollBar(MacroFrameScrollFrameScrollBar, 5)
	S:HandleScrollBar(MacroPopupScrollFrameScrollBar, 5)
	
	MacroFrame:Width(360)
	
	local buttons = {
		"MacroSaveButton",
		"MacroCancelButton",
		"MacroDeleteButton",
		"MacroNewButton",
		"MacroExitButton",
		"MacroEditButton",
		"MacroFrameTab1",
		"MacroFrameTab2",
		"MacroPopupOkayButton",
		"MacroPopupCancelButton",
	}
	
	for i = 1, #buttons do
		_G[buttons[i]]:StripTextures()
		S:HandleButton(_G[buttons[i]])
	end
	
	for i = 1, 2 do
		tab = _G[format("MacroFrameTab%s", i)]
		tab:Height(22)
	end
	MacroFrameTab1:Point("TOPLEFT", MacroFrame, "TOPLEFT", 85, -39)
	MacroFrameTab2:Point("LEFT", MacroFrameTab1, "RIGHT", 4, 0)
	

	-- General
	MacroFrame:StripTextures()
	MacroFrame:SetTemplate("Transparent")
	MacroFrameTextBackground:StripTextures()
	MacroFrameTextBackground:SetTemplate('Default')
	MacroButtonScrollFrame:CreateBackdrop()
	MacroPopupFrame:StripTextures()
	MacroPopupFrame:SetTemplate("Transparent")
	MacroPopupScrollFrame:StripTextures()
	MacroPopupScrollFrame:CreateBackdrop()
	MacroPopupScrollFrame.backdrop:Point("TOPLEFT", 51, 2)
	MacroPopupScrollFrame.backdrop:Point("BOTTOMRIGHT", -4, 4)
	MacroPopupEditBox:CreateBackdrop()
	MacroPopupEditBox:StripTextures()
	
	--Reposition edit button
	MacroEditButton:ClearAllPoints()
	MacroEditButton:Point("BOTTOMLEFT", MacroFrameSelectedMacroButton, "BOTTOMRIGHT", 10, 0)
	
	-- Regular scroll bar
	S:HandleScrollBar(MacroButtonScrollFrame)
	
	MacroPopupFrame:HookScript("OnShow", function(self)
		self:ClearAllPoints()
		self:Point("TOPLEFT", MacroFrame, "TOPRIGHT", 5, -2)
	end)
	
	-- Big icon
	MacroFrameSelectedMacroButton:StripTextures()
	MacroFrameSelectedMacroButton:StyleButton(true)
	MacroFrameSelectedMacroButton:GetNormalTexture():SetTexture(nil)
	MacroFrameSelectedMacroButton:SetTemplate("Default")
	MacroFrameSelectedMacroButtonIcon:SetTexCoord(unpack(E.TexCoords))
	MacroFrameSelectedMacroButtonIcon:ClearAllPoints()
	MacroFrameSelectedMacroButtonIcon:Point("TOPLEFT", 2, -2)
	MacroFrameSelectedMacroButtonIcon:Point("BOTTOMRIGHT", -2, 2)
	
	-- temporarily moving this text
	MacroFrameCharLimitText:ClearAllPoints()
	MacroFrameCharLimitText:Point("BOTTOM", MacroFrameTextBackground, 0, -70)
	
	-- Skin all buttons
	for i = 1, MAX_ACCOUNT_MACROS do
		local b = _G["MacroButton"..i]
		local t = _G["MacroButton"..i.."Icon"]
		local pb = _G["MacroPopupButton"..i]
		local pt = _G["MacroPopupButton"..i.."Icon"]
		
		if b then
			b:StripTextures()
			b:StyleButton(true)
			
			b:SetTemplate("Default", true)
		end
		
		if t then
			t:SetTexCoord(unpack(E.TexCoords))
			t:ClearAllPoints()
			t:Point("TOPLEFT", 2, -2)
			t:Point("BOTTOMRIGHT", -2, 2)
		end

		if pb then
			pb:StripTextures()
			pb:StyleButton(true)
			
			pb:SetTemplate("Default")					
		end
		
		if pt then
			pt:SetTexCoord(unpack(E.TexCoords))
			pt:ClearAllPoints()
			pt:Point("TOPLEFT", 2, -2)
			pt:Point("BOTTOMRIGHT", -2, 2)
		end
	end
end

S:RegisterSkin("Blizzard_MacroUI", LoadSkin)