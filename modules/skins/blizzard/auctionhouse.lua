local E, L, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, ProfileDB, GlobalDB
local S = E:GetModule('Skins')

local function LoadSkin()
	if E.global.skins.blizzard.enable ~= true or E.global.skins.blizzard.auctionhouse ~= true then return end
	S:HandleCloseButton(AuctionFrameCloseButton)
	S:HandleScrollBar(AuctionsScrollFrameScrollBar)
	AuctionFrame:StripTextures(true)
	AuctionFrame:SetTemplate("Transparent")
	AuctionFrame:CreateShadow("Default")
	
	BrowseFilterScrollFrame:StripTextures()
	BrowseScrollFrame:StripTextures()
	AuctionsScrollFrame:StripTextures()
	BidScrollFrame:StripTextures()
	
	S:HandleDropDownBox(BrowseDropDown)
	S:HandleDropDownBox(PriceDropDown)
	S:HandleDropDownBox(DurationDropDown)
	S:HandleScrollBar(BrowseFilterScrollFrameScrollBar)
	S:HandleScrollBar(BrowseScrollFrameScrollBar)
	
	S:HandleCheckBox(IsUsableCheckButton)
	S:HandleCheckBox(ShowOnPlayerCheckButton)
	
	if not E:IsPTRVersion() then
		S:HandleRotateButton(AuctionDressUpModelRotateLeftButton)
		S:HandleRotateButton(AuctionDressUpModelRotateRightButton)
		AuctionDressUpModelRotateRightButton:Point("TOPLEFT", AuctionDressUpModelRotateLeftButton, "TOPRIGHT", 4, 0)
		AuctionDressUpFrame:StripTextures()
		AuctionDressUpFrame:SetTemplate("Transparent")
		AuctionDressUpFrame:Point("TOPLEFT", AuctionFrame, "TOPRIGHT", 2, 0)
		S:HandleButton(AuctionDressUpFrameResetButton)
		AuctionDressUpFrameCloseButton:StripTextures()
		AuctionDressUpFrameCloseButton:SetNormalTexture(AuctionFrameCloseButton:GetNormalTexture():GetTexture())
		AuctionDressUpFrameCloseButton:SetPushedTexture(AuctionFrameCloseButton:GetPushedTexture():GetTexture())
		AuctionDressUpFrameCloseButton:SetHighlightTexture(AuctionFrameCloseButton:GetHighlightTexture():GetTexture())
		AuctionDressUpFrameCloseButton:SetDisabledTexture(AuctionFrameCloseButton:GetDisabledTexture():GetTexture())			
	else
		SideDressUpFrame:StripTextures()
		SideDressUpFrame:SetTemplate("Transparent")
		SideDressUpFrame:Point("TOPLEFT", AuctionFrame, "TOPRIGHT", 2, 0)
		S:HandleButton(SideDressUpModelResetButton)
		S:HandleCloseButton(SideDressUpModelCloseButton)
	end
	
	--Progress Frame
	AuctionProgressFrame:StripTextures()
	AuctionProgressFrame:SetTemplate("Transparent")
	AuctionProgressFrame:CreateShadow("Default")
	AuctionProgressFrameCancelButton:StyleButton()
	AuctionProgressFrameCancelButton:SetTemplate("Default")
	AuctionProgressFrameCancelButton:SetHitRectInsets(0, 0, 0, 0)
	AuctionProgressFrameCancelButton:GetNormalTexture():ClearAllPoints()
	AuctionProgressFrameCancelButton:GetNormalTexture():Point("TOPLEFT", 2, -2)
	AuctionProgressFrameCancelButton:GetNormalTexture():Point("BOTTOMRIGHT", -2, 2)
	AuctionProgressFrameCancelButton:GetNormalTexture():SetTexCoord(0.67, 0.37, 0.61, 0.26)
	AuctionProgressFrameCancelButton:Size(28, 28)
	AuctionProgressFrameCancelButton:Point("LEFT", AuctionProgressBar, "RIGHT", 8, 0)
	
	AuctionProgressBarIcon:SetTexCoord(0.67, 0.37, 0.61, 0.26)
	
	local backdrop = CreateFrame("Frame", nil, AuctionProgressBarIcon:GetParent())
	backdrop:Point("TOPLEFT", AuctionProgressBarIcon, "TOPLEFT", -2, 2)
	backdrop:Point("BOTTOMRIGHT", AuctionProgressBarIcon, "BOTTOMRIGHT", 2, -2)
	backdrop:SetTemplate("Default")
	AuctionProgressBarIcon:SetParent(backdrop)
	
	AuctionProgressBarText:ClearAllPoints()
	AuctionProgressBarText:SetPoint("CENTER")
	
	AuctionProgressBar:StripTextures()
	AuctionProgressBar:CreateBackdrop("Default")
	AuctionProgressBar:SetStatusBarTexture(E["media"].normTex)
	AuctionProgressBar:SetStatusBarColor(1, 1, 0)
	
	S:HandleNextPrevButton(BrowseNextPageButton)
	S:HandleNextPrevButton(BrowsePrevPageButton)
	
	local buttons = {
		"BrowseBidButton",
		"BidBidButton",
		"BrowseBuyoutButton",
		"BidBuyoutButton",
		"BrowseCloseButton",
		"BidCloseButton",
		"BrowseSearchButton",
		"AuctionsCreateAuctionButton",
		"AuctionsCancelAuctionButton",
		"AuctionsCloseButton",
		"BrowseResetButton",
		"AuctionsStackSizeMaxButton",
		"AuctionsNumStacksMaxButton",
	}
	
	for _, button in pairs(buttons) do
		S:HandleButton(_G[button])
	end
	
	-- Auctionator support
    if IsAddOnLoaded("Auctionator") then
        S:HandleDropDownBox(Atr_Duration)
        S:HandleDropDownBox(Atr_DropDownSL)
        S:HandleButton(Atr_Search_Button, true)
        S:HandleButton(Atr_Back_Button, true)
        S:HandleButton(Atr_Buy1_Button, true)
        S:HandleButton(Atr_Adv_Search_Button, true)
        S:HandleButton(Atr_FullScanButton, true)
        S:HandleButton(Auctionator1Button, true)
        S:HandleButton(Atr_ListTabsTab1, true)
        S:HandleButton(Atr_ListTabsTab2, true)
        S:HandleButton(Atr_ListTabsTab3, true)
        S:HandleButton(Atr_CreateAuctionButton, true)
        S:HandleButton(Atr_RemFromSListButton, true)
        S:HandleButton(Atr_AddToSListButton, true)
        S:HandleButton(Atr_SrchSListButton, true)
        S:HandleButton(Atr_MngSListsButton, true)
        S:HandleButton(Atr_NewSListButton, true)
        S:HandleButton(Atr_CheckActiveButton, true)
        S:HandleButton(AuctionatorCloseButton, true)
        S:HandleButton(Atr_CancelSelectionButton, true)
        S:HandleButton(Atr_FullScanStartButton, true)
        S:HandleButton(Atr_FullScanDone, true)
        S:HandleButton(Atr_CheckActives_Yes_Button, true)
        S:HandleButton(Atr_CheckActives_No_Button, true)
        S:HandleButton(Atr_Adv_Search_ResetBut, true)
        S:HandleButton(Atr_Adv_Search_OKBut, true)
        S:HandleButton(Atr_Adv_Search_CancelBut, true)
        S:HandleButton(Atr_Buy_Confirm_OKBut, true)
        S:HandleButton(Atr_Buy_Confirm_CancelBut, true)
        S:HandleButton(Atr_SaveThisList_Button, true)
        S:HandleEditBox(Atr_StackPriceGold)
        S:HandleEditBox(Atr_StackPriceSilver)
        S:HandleEditBox(Atr_StackPriceCopper)
        S:HandleEditBox(Atr_ItemPriceGold)
        S:HandleEditBox(Atr_ItemPriceSilver)
        S:HandleEditBox(Atr_ItemPriceCopper)
        S:HandleEditBox(Atr_Batch_NumAuctions)
        S:HandleEditBox(Atr_Batch_Stacksize)
        S:HandleEditBox(Atr_Search_Box)
        S:HandleEditBox(Atr_AS_Searchtext)
        S:HandleEditBox(Atr_AS_Minlevel)
        S:HandleEditBox(Atr_AS_Maxlevel)
        S:HandleEditBox(Atr_AS_MinItemlevel)
        S:HandleEditBox(Atr_AS_MaxItemlevel)      
		S:HandleScrollBar(Atr_Hlist_ScrollFrameScrollBar)
        Atr_FullScanResults:StripTextures()
        Atr_FullScanResults:SetTemplate("Transparent")
        Atr_Adv_Search_Dialog:StripTextures()
        Atr_Adv_Search_Dialog:SetTemplate("Transparent")
        Atr_FullScanFrame:StripTextures()
        Atr_FullScanFrame:SetTemplate("Transparent")
        Atr_HeadingsBar:StripTextures()
        Atr_HeadingsBar:SetTemplate("Default")
        Atr_HeadingsBar:Height(19)
        Atr_Error_Frame:StripTextures()
        Atr_Error_Frame:SetTemplate("Transparent")
        Atr_Hlist:StripTextures()
        Atr_Hlist:SetTemplate("Default")
        Atr_Hlist:Width(196)
        Atr_Hlist:ClearAllPoints()
        Atr_Hlist:Point("TOPLEFT", -195, -75)
        Atr_Buy_Confirm_Frame:StripTextures()
        Atr_Buy_Confirm_Frame:SetTemplate("Default")
        Atr_CheckActives_Frame:StripTextures()
        Atr_CheckActives_Frame:SetTemplate("Default")
        -- resize some buttons to fit
        Atr_SrchSListButton:Width(196)
        Atr_MngSListsButton:Width(196)
        Atr_NewSListButton:Width(196)
        Atr_CheckActiveButton:Width(196)

        -- Button Positions
        AuctionatorCloseButton:ClearAllPoints()
        AuctionatorCloseButton:Point("BOTTOMLEFT", Atr_Main_Panel, "BOTTOMRIGHT", -17, 10)
        Atr_Buy1_Button:Point("RIGHT", AuctionatorCloseButton, "LEFT", -5, 0)
        Atr_CancelSelectionButton:Point("RIGHT", Atr_Buy1_Button, "LEFT", -5, 0)
        Atr_SellControls_Tex:StripTextures()
        Atr_SellControls_Tex:StyleButton()
        Atr_SellControls_Tex:SetTemplate("Default", true)
    end

	
	--Fix Button Positions
	AuctionsCloseButton:Point("BOTTOMRIGHT", AuctionFrameAuctions, "BOTTOMRIGHT", 66, 10)
	AuctionsCancelAuctionButton:Point("RIGHT", AuctionsCloseButton, "LEFT", -4, 0)
	BidBuyoutButton:Point("RIGHT", BidCloseButton, "LEFT", -4, 0)
	BidBidButton:Point("RIGHT", BidBuyoutButton, "LEFT", -4, 0)
	BrowseBuyoutButton:Point("RIGHT", BrowseCloseButton, "LEFT", -4, 0)
	BrowseBidButton:Point("RIGHT", BrowseBuyoutButton, "LEFT", -4, 0)		
	AuctionsItemButton:StripTextures()
	AuctionsItemButton:StyleButton()
	AuctionsItemButton:SetTemplate("Default", true)
	BrowseResetButton:Point("TOPLEFT", AuctionFrameBrowse, "TOPLEFT", 81, -74)
	BrowseSearchButton:Point("TOPRIGHT", AuctionFrameBrowse, "TOPRIGHT", 25, -34)
	
	AuctionsItemButton:SetScript("OnUpdate", function()
		if AuctionsItemButton:GetNormalTexture() then
			AuctionsItemButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
			AuctionsItemButton:GetNormalTexture():ClearAllPoints()
			AuctionsItemButton:GetNormalTexture():Point("TOPLEFT", 2, -2)
			AuctionsItemButton:GetNormalTexture():Point("BOTTOMRIGHT", -2, 2)
		end
	end)
	
	local sorttabs = {
		"BrowseQualitySort",
		"BrowseLevelSort",
		"BrowseDurationSort",
		"BrowseHighBidderSort",
		"BrowseCurrentBidSort",
		"BidQualitySort",
		"BidLevelSort",
		"BidDurationSort",
		"BidBuyoutSort",
		"BidStatusSort",
		"BidBidSort",
		"AuctionsQualitySort",
		"AuctionsDurationSort",
		"AuctionsHighBidderSort",
		"AuctionsBidSort",
	}
	
	for _, sorttab in pairs(sorttabs) do
		_G[sorttab.."Left"]:Kill()
		_G[sorttab.."Middle"]:Kill()
		_G[sorttab.."Right"]:Kill()
	end
	
	for i=1, AuctionFrame.numTabs do
		S:HandleTab(_G["AuctionFrameTab"..i])
	end
	
	for i=1, NUM_FILTERS_TO_DISPLAY do
		local tab = _G["AuctionFilterButton"..i]
		tab:StripTextures()
		tab:StyleButton()
	end
	
	local editboxs = {
		"BrowseName",
		"BrowseMinLevel",
		"BrowseMaxLevel",
		"BrowseBidPriceGold",
		"BrowseBidPriceSilver",
		"BrowseBidPriceCopper",
		"BidBidPriceGold",
		"BidBidPriceSilver",
		"BidBidPriceCopper",
		"AuctionsStackSizeEntry",
		"AuctionsNumStacksEntry",
		"StartPriceGold",
		"StartPriceSilver",
		"StartPriceCopper",
		"BuyoutPriceGold",
		"BuyoutPriceSilver",
		"BuyoutPriceCopper"			
	}
	
	for _, editbox in pairs(editboxs) do
		S:HandleEditBox(_G[editbox])
		_G[editbox]:SetTextInsets(1, 1, -1, 1)
	end
	BrowseMaxLevel:Point("LEFT", BrowseMinLevel, "RIGHT", 8, 0)
	AuctionsStackSizeEntry.backdrop:SetAllPoints()
	AuctionsNumStacksEntry.backdrop:SetAllPoints()
	
	for i=1, NUM_BROWSE_TO_DISPLAY do
		local button = _G["BrowseButton"..i]
		local icon = _G["BrowseButton"..i.."Item"]
		
		if _G["BrowseButton"..i.."ItemIconTexture"] then
			_G["BrowseButton"..i.."ItemIconTexture"]:SetTexCoord(unpack(E.TexCoords))
			_G["BrowseButton"..i.."ItemIconTexture"]:ClearAllPoints()
			_G["BrowseButton"..i.."ItemIconTexture"]:Point("TOPLEFT", 2, -2)
			_G["BrowseButton"..i.."ItemIconTexture"]:Point("BOTTOMRIGHT", -2, 2)
		end
		
		if icon then
			icon:StyleButton()
			--TODO: Find a better method to ensure that the icon:GetNormalTexture doesn't return after clicking
			icon:HookScript("OnUpdate", function() icon:GetNormalTexture():Kill() end)
		
			icon:CreateBackdrop("Default")
			icon.backdrop:SetAllPoints()
		end
		
		if button then
			button:StripTextures()
			button:StyleButton()
			_G["BrowseButton"..i.."Highlight"] = button:GetHighlightTexture()
			button:GetHighlightTexture():ClearAllPoints()
			button:GetHighlightTexture():Point("TOPLEFT", icon, "TOPRIGHT", 2, 0)
			button:GetHighlightTexture():SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
			button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())
		end
	end
	
	for i=1, NUM_AUCTIONS_TO_DISPLAY do
		local button = _G["AuctionsButton"..i]
		local icon = _G["AuctionsButton"..i.."Item"]
		
		_G["AuctionsButton"..i.."ItemIconTexture"]:SetTexCoord(unpack(E.TexCoords))
		_G["AuctionsButton"..i.."ItemIconTexture"].SetTexCoord = E.noop
		_G["AuctionsButton"..i.."ItemIconTexture"]:ClearAllPoints()
		_G["AuctionsButton"..i.."ItemIconTexture"]:Point("TOPLEFT", 2, -2)
		_G["AuctionsButton"..i.."ItemIconTexture"]:Point("BOTTOMRIGHT", -2, 2)
		
		icon:StyleButton()
		--TODO: Find a better method to ensure that the icon:GetNormalTexture doesn't return after clicking
		icon:HookScript("OnUpdate", function() icon:GetNormalTexture():Kill() end)
		
		icon:CreateBackdrop("Default")
		icon.backdrop:SetAllPoints()

		button:StripTextures()
		button:StyleButton()
		_G["AuctionsButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		button:GetHighlightTexture():Point("TOPLEFT", icon, "TOPRIGHT", 2, 0)
		button:GetHighlightTexture():SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())		
	end
	
	for i=1, NUM_BIDS_TO_DISPLAY do
		local button = _G["BidButton"..i]
		local icon = _G["BidButton"..i.."Item"]
		
		_G["BidButton"..i.."ItemIconTexture"]:SetTexCoord(unpack(E.TexCoords))
		_G["BidButton"..i.."ItemIconTexture"]:ClearAllPoints()
		_G["BidButton"..i.."ItemIconTexture"]:Point("TOPLEFT", 2, -2)
		_G["BidButton"..i.."ItemIconTexture"]:Point("BOTTOMRIGHT", -2, 2)
		
		icon:StyleButton()
		icon:HookScript("OnUpdate", function() icon:GetNormalTexture():Kill() end)
		
		icon:CreateBackdrop("Default")
		icon.backdrop:SetAllPoints()

		button:StripTextures()
		button:StyleButton()
		_G["BidButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		button:GetHighlightTexture():Point("TOPLEFT", icon, "TOPRIGHT", 2, 0)
		button:GetHighlightTexture():SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())			
	end
	
	--[[for i=1, AuctionFrameBrowse:GetNumRegions() do 
		local region = select(i, AuctionFrameBrowse:GetRegions());
		if region:GetObjectType() == "FontString" then 
			print(region:GetText(), region:GetName()) 
		end 
	end]]
	
	--Custom Backdrops
	AuctionFrameBrowse.bg1 = CreateFrame("Frame", nil, AuctionFrameBrowse)
	AuctionFrameBrowse.bg1:SetTemplate("Default")
	AuctionFrameBrowse.bg1:Point("TOPLEFT", 20, -103)
	AuctionFrameBrowse.bg1:Point("BOTTOMRIGHT", -575, 40)
	BrowseNoResultsText:SetParent(AuctionFrameBrowse.bg1)
	BrowseSearchCountText:SetParent(AuctionFrameBrowse.bg1)
	AuctionFrameBrowse.bg1:SetFrameLevel(AuctionFrameBrowse.bg1:GetFrameLevel() - 1)
	BrowseFilterScrollFrame:Height(300) --Adjust scrollbar height a little off

	AuctionFrameBrowse.bg2 = CreateFrame("Frame", nil, AuctionFrameBrowse)
	AuctionFrameBrowse.bg2:SetTemplate("Default")
	AuctionFrameBrowse.bg2:Point("TOPLEFT", AuctionFrameBrowse.bg1, "TOPRIGHT", 4, 0)
	AuctionFrameBrowse.bg2:Point("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -8, 40)
	AuctionFrameBrowse.bg2:SetFrameLevel(AuctionFrameBrowse.bg2:GetFrameLevel() - 1)
	BrowseScrollFrame:Height(300) --Adjust scrollbar height a little off
	
	AuctionFrameBid.bg = CreateFrame("Frame", nil, AuctionFrameBid)
	AuctionFrameBid.bg:SetTemplate("Default")
	AuctionFrameBid.bg:Point("TOPLEFT", 22, -72)
	AuctionFrameBid.bg:Point("BOTTOMRIGHT", 66, 39)
	AuctionFrameBid.bg:SetFrameLevel(AuctionFrameBid.bg:GetFrameLevel() - 1)
	BidScrollFrame:Height(332)	

	AuctionsScrollFrame:Height(336)	
	AuctionFrameAuctions.bg1 = CreateFrame("Frame", nil, AuctionFrameAuctions)
	AuctionFrameAuctions.bg1:SetTemplate("Default")
	AuctionFrameAuctions.bg1:Point("TOPLEFT", 15, -70)
	AuctionFrameAuctions.bg1:Point("BOTTOMRIGHT", -545, 35)  
	AuctionFrameAuctions.bg1:SetFrameLevel(AuctionFrameAuctions.bg1:GetFrameLevel() - 2)	
	
	AuctionFrameAuctions.bg2 = CreateFrame("Frame", nil, AuctionFrameAuctions)
	AuctionFrameAuctions.bg2:SetTemplate("Default")
	AuctionFrameAuctions.bg2:Point("TOPLEFT", AuctionFrameAuctions.bg1, "TOPRIGHT", 3, 0)
	AuctionFrameAuctions.bg2:Point("BOTTOMRIGHT", AuctionFrame, -8, 35)  
	AuctionFrameAuctions.bg2:SetFrameLevel(AuctionFrameAuctions.bg2:GetFrameLevel() - 2)	
end

S:RegisterSkin("Blizzard_AuctionUI", LoadSkin)