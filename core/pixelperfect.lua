local E, L, DF = unpack(select(2, ...)); --Engine

--Determine if Eyefinity is being used, setup the pixel perfect script.
local scale
function E:UIScale(event)
	if self.db.core.autoscale == true then
		scale = min(1, max(.64, 768/self.screenheight));
	else
		scale = self.db["core"].uiscale
	end

	if self.screenwidth < 1600 then
			self.lowversion = true;
	elseif self.screenwidth >= 3840 --[[or (UIParent:GetWidth() + 1 > self.screenwidth)]] then
		local width = self.screenwidth;
		local height = self.screenheight;
	
		-- because some user enable bezel compensation, we need to find the real width of a single monitor.
		-- I don't know how it really work, but i'm assuming they add pixel to width to compensate the bezel. :P

		-- HQ resolution
		if width >= 9840 then width = 3280; end                   	                -- WQSXGA
		if width >= 7680 and width < 9840 then width = 2560; end                     -- WQXGA
		if width >= 5760 and width < 7680 then width = 1920; end 	                -- WUXGA & HDTV
		if width >= 5040 and width < 5760 then width = 1680; end 	                -- WSXGA+

		-- adding height condition here to be sure it work with bezel compensation because WSXGA+ and UXGA/HD+ got approx same width
		if width >= 4800 and width < 5760 and height == 900 then width = 1600; end   -- UXGA & HD+

		-- low resolution screen
		if width >= 4320 and width < 4800 then width = 1440; end 	                -- WSXGA
		if width >= 4080 and width < 4320 then width = 1360; end 	                -- WXGA
		if width >= 3840 and width < 4080 then width = 1224; end 	                -- SXGA & SXGA (UVGA) & WXGA & HDTV
		
		-- yep, now set ElvUI to lower resolution if screen #1 width < 1600
		if width < 1600 then
			self.lowversion = true;
		end
		
		-- register a constant, we will need it later for launch.lua
		self.eyefinity = width;
	end
	
	self.mult = 768/string.match(GetCVar("gxResolution"), "%d+x(%d+)")/scale;

	--Set UIScale, NOTE: SetCVar for UIScale can cause taints so only do this when we need to..
	if E.Round and E:Round(UIParent:GetScale(), 5) ~= E:Round(scale, 5) and event == 'PLAYER_LOGIN' then
		SetCVar("useUiScale", 1);
		SetCVar("uiScale", scale);	
	end	
	
	if event == 'PLAYER_LOGIN' then
		--Resize self.UIParent if Eyefinity is on.
		if self.eyefinity then
			local width = self.eyefinity;
			local height = self.screenheight;
			
			-- if autoscale is off, find a new width value of self.UIParent for screen #1.
			if not self.db["core"].autoscale or height > 1200 then
				local h = UIParent:GetHeight();
				local ratio = self.screenheight / h;
				local w = self.eyefinity / ratio;
				
				width = w;
				height = h;	
			end
			
			self.UIParent:SetSize(width, height);
		else
			--[[Eyefinity Test mode
				Resize the E.UIParent to be smaller than it should be, all objects inside should relocate.
				Dragging moveable frames outside the box and reloading the UI ensures that they are saving position correctly.
			]]
			--self.UIParent:SetSize(UIParent:GetWidth() - 250, UIParent:GetHeight() - 250);

			self.UIParent:SetSize(UIParent:GetSize());
		end		
			
		self.UIParent:ClearAllPoints();
		self.UIParent:SetPoint("CENTER");	

		self:UnregisterEvent('PLAYER_LOGIN')		
	end
end

-- pixel perfect script of custom ui scale.
function E:Scale(x)
	if not self.mult then self:UIScale() end
    return self.mult*math.floor(x/self.mult+.5);
end