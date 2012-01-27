local E, L, DF = unpack(select(2, ...)); --Engine
local S = E:GetModule('Skins')

--Tab Regions
local tabs = {
	"LeftDisabled",
	"MiddleDisabled",
	"RightDisabled",
	"Left",
	"Middle",
	"Right",
}

--Social Frame
local function SkinSocialHeaderTab(tab)
	if not tab then return end
	for _, object in pairs(tabs) do
		local tex = _G[tab:GetName()..object]
		tex:SetTexture(nil)
	end
	tab:GetHighlightTexture():SetTexture(nil)
	tab.backdrop = CreateFrame("Frame", nil, tab)
	tab.backdrop:SetTemplate("Default")
	tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
	tab.backdrop:Point("TOPLEFT", 3, -8)
	tab.backdrop:Point("BOTTOMRIGHT", -6, 0)
end

local function LoadSkin()
	if E.db.skins.blizzard.enable ~= true or E.db.skins.blizzard.friends ~= true then return end
	S:HandleScrollBar(FriendsFrameFriendsScrollFrameScrollBar, 5)
	S:HandleScrollBar(WhoListScrollFrameScrollBar, 5)
	S:HandleScrollBar(ChannelRosterScrollFrameScrollBar, 5)
	local StripAllTextures = {
		"FriendsListFrame",
		"FriendsTabHeader",
		"FriendsFrameFriendsScrollFrame",
		"WhoFrameColumnHeader1",
		"WhoFrameColumnHeader2",
		"WhoFrameColumnHeader3",
		"WhoFrameColumnHeader4",
		"ChannelListScrollFrame",
		"ChannelRoster",
		"FriendsFramePendingButton1",
		"FriendsFramePendingButton2",
		"FriendsFramePendingButton3",
		"FriendsFramePendingButton4",
		"ChannelFrameDaughterFrame",
		"AddFriendFrame",
		"AddFriendNoteFrame",
	}			

	local KillTextures = {
		"FriendsFrameBroadcastInputLeft",
		"FriendsFrameBroadcastInputRight",
		"FriendsFrameBroadcastInputMiddle",
		"ChannelFrameDaughterFrameChannelNameLeft",
		"ChannelFrameDaughterFrameChannelNameRight",
		"ChannelFrameDaughterFrameChannelNameMiddle",
		"ChannelFrameDaughterFrameChannelPasswordLeft",
		"ChannelFrameDaughterFrameChannelPasswordRight",				
		"ChannelFrameDaughterFrameChannelPasswordMiddle",			
	}
	
	if E:IsPTRVersion() then
		FriendsFrameInset:StripTextures()
		WhoFrameListInset:StripTextures()
		WhoFrameEditBoxInset:StripTextures()
		ChannelFrameRightInset:StripTextures()
		ChannelFrameLeftInset:StripTextures()
		LFRQueueFrameListInset:StripTextures()
		LFRQueueFrameRoleInset:StripTextures()
		LFRQueueFrameCommentInset:StripTextures()
	else
		FriendsFrameTopLeft:Kill()
		FriendsFrameTopRight:Kill()
		FriendsFrameBottomLeft:Kill()
		FriendsFrameBottomRight:Kill()
		ChannelFrameVerticalBar:Kill()
	end

	local buttons = {
		"FriendsFrameAddFriendButton",
		"FriendsFrameSendMessageButton",
		"WhoFrameWhoButton",
		"WhoFrameAddFriendButton",
		"WhoFrameGroupInviteButton",
		"ChannelFrameNewButton",
		"FriendsFrameIgnorePlayerButton",
		"FriendsFrameUnsquelchButton",
		"FriendsFramePendingButton1AcceptButton",
		"FriendsFramePendingButton1DeclineButton",
		"FriendsFramePendingButton2AcceptButton",
		"FriendsFramePendingButton2DeclineButton",
		"FriendsFramePendingButton3AcceptButton",
		"FriendsFramePendingButton3DeclineButton",
		"FriendsFramePendingButton4AcceptButton",
		"FriendsFramePendingButton4DeclineButton",
		"ChannelFrameDaughterFrameOkayButton",
		"ChannelFrameDaughterFrameCancelButton",
		"AddFriendEntryFrameAcceptButton",
		"AddFriendEntryFrameCancelButton",
		"AddFriendInfoFrameContinueButton",
	}			

	for _, button in pairs(buttons) do
		S:HandleButton(_G[button])
	end
	--Reposition buttons
	if not E:IsPTRVersion() then
		WhoFrameWhoButton:Point("RIGHT", WhoFrameAddFriendButton, "LEFT", -2, 0)
		WhoFrameAddFriendButton:Point("RIGHT", WhoFrameGroupInviteButton, "LEFT", -2, 0)
		WhoFrameGroupInviteButton:Point("BOTTOMRIGHT", WhoFrame, "BOTTOMRIGHT", -44, 82)
		--Resize Buttons
		WhoFrameWhoButton:Size(WhoFrameWhoButton:GetWidth() - 4, WhoFrameWhoButton:GetHeight())
		WhoFrameAddFriendButton:Size(WhoFrameAddFriendButton:GetWidth() - 4, WhoFrameAddFriendButton:GetHeight())
		WhoFrameGroupInviteButton:Size(WhoFrameGroupInviteButton:GetWidth() - 4, WhoFrameGroupInviteButton:GetHeight())
		S:HandleEditBox(WhoFrameEditBox)
		WhoFrameEditBox:Height(WhoFrameEditBox:GetHeight() - 15)
		WhoFrameEditBox:Point("BOTTOM", WhoFrame, "BOTTOM", -10, 108)
		WhoFrameEditBox:Width(WhoFrameEditBox:GetWidth() + 17)
	end
	
	for _, texture in pairs(KillTextures) do
		_G[texture]:Kill()
	end

	for _, object in pairs(StripAllTextures) do
		_G[object]:StripTextures()
	end

	for i=1, FriendsFrame:GetNumRegions() do
		local region = select(i, FriendsFrame:GetRegions())
		if region:GetObjectType() == "Texture" then
			region:SetTexture(nil)
			region:SetAlpha(0)
		end
	end	

	S:HandleEditBox(AddFriendNameEditBox)
	AddFriendFrame:SetTemplate("Transparent")			
	
	--Who Frame
	local function UpdateWhoSkins()
		WhoListScrollFrame:StripTextures()
	end
	--Channel Frame
	local function UpdateChannel()
		ChannelRosterScrollFrame:StripTextures()
	end
	--BNet Frame
	FriendsFrameBroadcastInput:CreateBackdrop("Default")
	ChannelFrameDaughterFrameChannelName:CreateBackdrop("Default")
	ChannelFrameDaughterFrameChannelPassword:CreateBackdrop("Default")			

	ChannelFrame:HookScript("OnShow", UpdateChannel)
	hooksecurefunc("FriendsFrame_OnEvent", UpdateChannel)

	WhoFrame:HookScript("OnShow", UpdateWhoSkins)
	hooksecurefunc("FriendsFrame_OnEvent", UpdateWhoSkins)

	ChannelFrameDaughterFrame:CreateBackdrop("Transparent")
	
	if E:IsPTRVersion() then
		FriendsFrame:SetTemplate('Transparent')
	else
		FriendsFrame:CreateBackdrop("Transparent")
		FriendsFrame.backdrop:Point( "TOPLEFT", FriendsFrame, "TOPLEFT", 11,-12)
		FriendsFrame.backdrop:Point( "BOTTOMRIGHT", FriendsFrame, "BOTTOMRIGHT", -35, 76)
	end
	
	S:HandleCloseButton(ChannelFrameDaughterFrameDetailCloseButton,ChannelFrameDaughterFrame)
	S:HandleCloseButton(FriendsFrameCloseButton,FriendsFrame.backdrop)
	S:HandleDropDownBox(WhoFrameDropDown,150)
	S:HandleDropDownBox(FriendsFrameStatusDropDown,70)

	--Bottom Tabs
	for i=1, 4 do
		S:HandleTab(_G["FriendsFrameTab"..i])
	end

	for i=1, 3 do
		SkinSocialHeaderTab(_G["FriendsTabHeaderTab"..i])
	end

	local function Channel()
		for i=1, MAX_DISPLAY_CHANNEL_BUTTONS do
			local button = _G["ChannelButton"..i]
			if button then
				button:StripTextures()
				button:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
				
				_G["ChannelButton"..i.."Text"]:FontTemplate(nil, 12)
			end
		end
	end
	hooksecurefunc("ChannelList_Update", Channel)
	
	--View Friends BN Frame
	FriendsFriendsFrame:CreateBackdrop("Transparent")

	local StripAllTextures = {
		"FriendsFriendsFrame",
		"FriendsFriendsList",
		"FriendsFriendsNoteFrame",
	}

	local buttons = {
		"FriendsFriendsSendRequestButton",
		"FriendsFriendsCloseButton",
	}

	for _, object in pairs(StripAllTextures) do
		_G[object]:StripTextures()
	end

	for _, button in pairs(buttons) do
		S:HandleButton(_G[button])
	end

	S:HandleEditBox(FriendsFriendsList)
	S:HandleEditBox(FriendsFriendsNoteFrame)
	S:HandleDropDownBox(FriendsFriendsFrameDropDown,150)
	
	BNConversationInviteDialog:StripTextures()
	BNConversationInviteDialog:CreateBackdrop('Transparent')
	BNConversationInviteDialogList:StripTextures()
	BNConversationInviteDialogList:SetTemplate('Default')
	S:HandleButton(BNConversationInviteDialogInviteButton)
	S:HandleButton(BNConversationInviteDialogCancelButton)
	
	for i=1, BN_CONVERSATION_INVITE_NUM_DISPLAYED do
		S:HandleCheckBox(_G["BNConversationInviteDialogListFriend"..i].checkButton)
	end
	
	if E:IsPTRVersion() then
		FriendsTabHeaderSoRButton:SetTemplate('Default')
		FriendsTabHeaderSoRButton:StyleButton()
		FriendsTabHeaderSoRButtonIcon:SetDrawLayer('OVERLAY')
		FriendsTabHeaderSoRButtonIcon:SetTexCoord(unpack(E.TexCoords))
		FriendsTabHeaderSoRButtonIcon:ClearAllPoints()
		FriendsTabHeaderSoRButtonIcon:Point('TOPLEFT', 2, -2)
		FriendsTabHeaderSoRButtonIcon:Point('BOTTOMRIGHT', -2, 2)
		FriendsTabHeaderSoRButton:Point('TOPRIGHT', FriendsTabHeader, 'TOPRIGHT', -8, -56)
		
		S:HandleScrollBar(FriendsFrameIgnoreScrollFrameScrollBar, 4)
		S:HandleScrollBar(FriendsFramePendingScrollFrameScrollBar, 4)
		
		IgnoreListFrame:StripTextures()
		PendingListFrame:StripTextures()
		
		ScrollOfResurrectionFrame:StripTextures()
		S:HandleButton(ScrollOfResurrectionFrameAcceptButton)
		S:HandleButton(ScrollOfResurrectionFrameCancelButton)
		
		ScrollOfResurrectionFrameTargetEditBoxLeft:SetTexture(nil)
		ScrollOfResurrectionFrameTargetEditBoxMiddle:SetTexture(nil)
		ScrollOfResurrectionFrameTargetEditBoxRight:SetTexture(nil)
		ScrollOfResurrectionFrameNoteFrame:StripTextures()
		ScrollOfResurrectionFrameNoteFrame:SetTemplate()
		ScrollOfResurrectionFrameTargetEditBox:SetTemplate()
		ScrollOfResurrectionFrame:SetTemplate('Transparent')
		ScrollOfResurrectionFrame:CreateShadow()
	end
end

S:RegisterSkin('ElvUI', LoadSkin)