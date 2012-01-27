local E, L, DF = unpack(select(2, ...)); --Engine
local AB = E:GetModule('ActionBars');

local ceil = math.ceil;

local bar = CreateFrame('Frame', 'ElvUI_BarPet', E.UIParent, 'SecureHandlerStateTemplate');

function AB:UpdatePet()
	for i=1, NUM_PET_ACTION_SLOTS, 1 do
		local buttonName = "PetActionButton"..i;
		local button = _G[buttonName];
		local icon = _G[buttonName.."Icon"];
		local autoCast = _G[buttonName.."AutoCastable"];
		local shine = _G[buttonName.."Shine"];	
		local checked = button:GetCheckedTexture();
		local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i);

		if not isToken then
			icon:SetTexture(texture);
			button.tooltipName = name;
		else
			icon:SetTexture(_G[texture]);
			button.tooltipName = _G[name];
		end		
		
		button.isToken = isToken;
		button.tooltipSubtext = subtext;	
		
		if isActive and name ~= "PET_ACTION_FOLLOW" then
			button:SetChecked(1);
			if IsPetAttackAction(i) then
				PetActionButton_StartFlash(button);
			end
		else
			button:SetChecked(0);
			if IsPetAttackAction(i) then
				PetActionButton_StopFlash(button);
			end			
		end		
		
		if autoCastAllowed then
			autoCast:Show();
		else
			autoCast:Hide();
		end		
		
		if autoCastEnabled then
			AutoCastShine_AutoCastStart(shine);
		else
			AutoCastShine_AutoCastStop(shine);
		end		
		
		button:SetAlpha(1);
		
		if texture then
			if GetPetActionSlotUsable(i) then
				SetDesaturation(icon, nil);
			else
				SetDesaturation(icon, 1);
			end
			icon:Show();
		else
			icon:Hide();
		end		
		
		if not PetHasActionBar() and texture and name ~= "PET_ACTION_FOLLOW" then
			PetActionButton_StopFlash(button);
			SetDesaturation(icon, 1);
			button:SetChecked(0);
		end		
		
		checked:SetAlpha(0.3);
	end
end

function AB:PositionAndSizeBarPet()
	local spacing = E:Scale(self.db.buttonspacing);
	local buttonsPerRow = self.db['barPet'].buttonsPerRow;
	local numButtons = self.db['barPet'].buttons;
	local size = E:Scale(self.db.altbuttonsize);
	local point = self.db['barPet'].point;
	local numColumns = ceil(numButtons / buttonsPerRow);
	local widthMult = self.db['barPet'].widthMult;
	local heightMult = self.db['barPet'].heightMult;
	
	if numButtons < buttonsPerRow then
		buttonsPerRow = numButtons;
	end

	if numColumns < 1 then
		numColumns = 1;
	end

	bar:SetWidth(spacing + ((size * (buttonsPerRow * widthMult)) + ((spacing * (buttonsPerRow - 1)) * widthMult) + (spacing * widthMult)));
	bar:SetHeight(spacing + ((size * (numColumns * heightMult)) + ((spacing * (numColumns - 1)) * heightMult) + (spacing * heightMult)));
	bar.mover:SetWidth(spacing + ((size * (buttonsPerRow * widthMult)) + ((spacing * (buttonsPerRow - 1)) * widthMult) + (spacing * widthMult)));
	bar.mover:SetHeight(spacing + ((size * (numColumns * heightMult)) + ((spacing * (numColumns - 1)) * heightMult) + (spacing * heightMult)));
	bar.mouseover = self.db['barPet'].mouseover
	if self.db['barPet'].enabled then
		bar:SetScale(1);
		bar:SetAlpha(1);
	else
		bar:SetScale(0.000001);
		bar:SetAlpha(0);
	end
	
	if self.db['barPet'].backdrop == true then
		bar.backdrop:Show();
	else
		bar.backdrop:Hide();
	end
	
	local horizontalGrowth, verticalGrowth;
	if point == "TOPLEFT" or point == "TOPRIGHT" then
		verticalGrowth = "DOWN";
	else
		verticalGrowth = "UP";
	end
	
	if point == "BOTTOMLEFT" or point == "TOPLEFT" then
		horizontalGrowth = "RIGHT";
	else
		horizontalGrowth = "LEFT";
	end
	
	local button, lastButton, lastColumnButton; 
	local possibleButtons = {};
	for i=1, NUM_PET_ACTION_SLOTS do
		button = _G["PetActionButton"..i];
		lastButton = _G["PetActionButton"..i-1];
		lastColumnButton = _G["PetActionButton"..i-buttonsPerRow];
		button:SetParent(bar);
		button:ClearAllPoints();
		button:Size(self.db.altbuttonsize);
		
		possibleButtons[((i * buttonsPerRow) + 1)] = true;
		button:SetAttribute("showgrid", 1);

		if self.db['barPet'].mouseover == true then
			bar:SetAlpha(0);
			if not self.hooks[bar] then
				self:HookScript(bar, 'OnEnter', 'Bar_OnEnter');
				self:HookScript(bar, 'OnLeave', 'Bar_OnLeave');	
			end
			
			if not self.hooks[button] then
				self:HookScript(button, 'OnEnter', 'Button_OnEnter');
				self:HookScript(button, 'OnLeave', 'Button_OnLeave');					
			end
		else
			bar:SetAlpha(1);
			if self.hooks[bar] then
				self:Unhook(bar, 'OnEnter');
				self:Unhook(bar, 'OnLeave');	
			end
			
			if self.hooks[button] then
				self:Unhook(button, 'OnEnter');	
				self:Unhook(button, 'OnLeave');		
			end
		end
		
		if i == 1 then
			local x, y;
			if point == "BOTTOMLEFT" then
				x, y = spacing, spacing;
			elseif point == "TOPRIGHT" then
				x, y = -spacing, -spacing;
			elseif point == "TOPLEFT" then
				x, y = spacing, -spacing;
			else
				x, y = -spacing, spacing;
			end

			button:Point(point, bar, point, x, y);
		elseif possibleButtons[i] then
			local x = 0;
			local y = -spacing;
			local buttonPoint, anchorPoint = "TOP", "BOTTOM";
			if verticalGrowth == 'UP' then
				y = spacing;
				buttonPoint = "BOTTOM";
				anchorPoint = "TOP";
			end
			button:Point(buttonPoint, lastColumnButton, anchorPoint, x, y);			
		else
			local x = spacing;
			local y = 0;
			local buttonPoint, anchorPoint = "LEFT", "RIGHT";
			if horizontalGrowth == 'LEFT' then
				x = -spacing;
				buttonPoint = "RIGHT";
				anchorPoint = "LEFT";
			end
			
			button:Point(buttonPoint, lastButton, anchorPoint, x, y);
		end
		
		if i > numButtons then
			button:SetScale(0.000001);
			button:SetAlpha(0);
		else
			button:SetScale(1);
			button:SetAlpha(1);
		end
		
		self:StyleButton(button, true);
	end
	possibleButtons = nil;
	
	RegisterStateDriver(bar, "show", self.db['barPet'].visibility);
end

function AB:CreateBarPet()
	bar:CreateBackdrop('Default');
	bar.backdrop:SetAllPoints();
	bar:Point('RIGHT', ElvUI_Bar4, 'LEFT', -4, 0);

	bar:SetAttribute("_onstate-show", [[		
		if newstate == "hide" then
			self:Hide();
		else
			self:Show();
		end	
	]]);
	
	PetActionBarFrame.showgrid = 1;
	PetActionBar_ShowGrid();
	
	self:RegisterEvent('PLAYER_CONTROL_GAINED', 'UpdatePet');
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdatePet');
	self:RegisterEvent('PLAYER_CONTROL_LOST', 'UpdatePet');
	self:RegisterEvent('PET_BAR_UPDATE', 'UpdatePet');
	self:RegisterEvent('UNIT_PET', 'UpdatePet');
	self:RegisterEvent('UNIT_FLAGS', 'UpdatePet');
	self:RegisterEvent('UNIT_AURA', 'UpdatePet');
	self:RegisterEvent('PLAYER_FARSIGHT_FOCUS_CHANGED', 'UpdatePet');
	self:RegisterEvent('PET_BAR_UPDATE_COOLDOWN', PetActionBar_UpdateCooldowns);
	
	self:CreateMover(bar, 'PetAB', 'barPet');
	self:PositionAndSizeBarPet();
end