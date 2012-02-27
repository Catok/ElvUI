local E, L, DF = unpack(select(2, ...)); --Engine
local S = E:GetModule('Skins')

-- Used to strip unecessary options from the in-game config
local function StripOptions(options)
	options.baroptions.args.barspacing = nil
	options.titleoptions.args.texture = nil
	options.titleoptions.args.bordertexture = nil
	options.titleoptions.args.thickness = nil
	options.titleoptions.args.margin = nil
	options.titleoptions.args.color = nil
	options.windowoptions = nil
	options.baroptions.args.barfont = nil
	options.titleoptions.args.font = nil
end

local function LoadSkin()
	if E.db.skins.skada.enable ~= true then return end
	local Skada = Skada
	local barSpacing = 1
	local borderWidth = 1
	local barmod = Skada.displays["bar"]

	barmod.AddDisplayOptions_ = barmod.AddDisplayOptions
	barmod.AddDisplayOptions = function(self, win, options)
		self:AddDisplayOptions_(win, options)
		StripOptions(options)
	end

	for k, options in pairs(Skada.options.args.windows.args) do
		if options.type == "group" then
			StripOptions(options.args)
		end
	end

	local titleBG = {
		bgFile = E["media"].normTex,
		tile = false,
		tileSize = 0
	}

	barmod.ApplySettings_ = barmod.ApplySettings
	barmod.ApplySettings = function(self, win)
		barmod.ApplySettings_(self, win)

		local skada = win.bargroup

		if win.db.enabletitle then
			skada.button:SetBackdrop(titleBG)
		end

		skada:SetSpacing(barSpacing)
		skada:SetFrameLevel(5)
		
		local titlefont = CreateFont("TitleFont"..win.db.name)
		win.bargroup.button:SetNormalFontObject(titlefont)

		win.bargroup.button:SetBackdropColor(unpack(E["media"].backdropcolor))

		skada:SetBackdrop(nil)
		if not skada.backdrop then
			skada:CreateBackdrop('Default')
		end
		skada.backdrop:ClearAllPoints()
		if win.db.enabletitle then
			skada.backdrop:Point('TOPLEFT', win.bargroup.button, 'TOPLEFT', -2, 2)
		else
			skada.backdrop:Point('TOPLEFT', win.bargroup, 'TOPLEFT', -2, 2)
		end
		skada.backdrop:Point('BOTTOMRIGHT', win.bargroup, 'BOTTOMRIGHT', 2, -2)
	end	
	
	-- Update pre-existing displays
	for _, window in ipairs(Skada:GetWindows()) do
		window:UpdateDisplay()
	end	
	
	
	if RightChatTab then
        local button = CreateFrame('Button', 'SkadaToggleSwitch', RightChatTab)
        button:Width(22)
        button:Height(20)
        button:Point("RIGHT", RightChatTab, "RIGHT", 0, 24)
        button.tex = button:CreateTexture(nil, 'OVERLAY')
        button.tex:SetTexture([[Interface\AddOns\ElvUI\media\textures\vehicleexit.tga]])
        button.tex:Point('TOPRIGHT', -2, -2)
        button.tex:Height(button:GetHeight())
        button.tex:Width(22)
		button:SetAlpha(0)
        button:SetScript('OnEnter', function(self) button:SetAlpha(1) end)
		button:SetScript('OnLeave', function(self) button:SetAlpha(0) end)
		button:SetScript('OnMouseDown', function(self) self.tex:Point('TOPRIGHT', -4, -4) end)
        button:SetScript('OnMouseUp', function(self) self.tex:Point('TOPRIGHT', -2, -2) end)
        button:SetScript('OnClick', function(self) Skada:ToggleWindow() end)
    end

end

S:RegisterSkin('Skada', LoadSkin)