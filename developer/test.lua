--[[
	Going to leave this as my bullshit lua file.
	
	So I can test stuff.
]]

SLASH_TEST1 = "/testui"
SlashCmdList["TEST"] = function(msg)
 if msg == "hide" then
	for _, frames in pairs({"ElvUF_Target", "ElvUF_TargetTarget", "ElvUF_Pet", "ElvUF_Focus", "ElvUF_FocusTarget"}) do
        _G[frames].Hide = nil
    end
    
    for i = 1, 5 do
		_G["ElvUF_Arena"..i].Hide = nil
	end
	
	for i = 1, 4 do
		_G["ElvUF_Boss"..i].Hide = nil
	end
	
	local name, rank, texture, count, dtype, duration, timeLeft, caster = UnitAura("player",1)
	if texture == 'Interface\\Icons\\Spell_Holy_Penance' then
		UnitAura = function()
            -- name, rank, texture, count, dtype, duration, timeLeft, caster
            return
        end
        if(oUF) then
            for i, v in pairs(oUF.units) do
                if(v.UNIT_AURA) then
                    v:UNIT_AURA("UNIT_AURA", v.unit)
                end
            end
        end
	end
 elseif msg == "buffs" then -- better dont test it ^^
        UnitAura = function()
            -- name, rank, texture, count, dtype, duration, timeLeft, caster
            return 139, 'Rank 1', 'Interface\\Icons\\Spell_Holy_Penance', 1, 'Magic', 0, 0, "player"
        end
        if(oUF) then
            for i, v in pairs(oUF.units) do
                if(v.UNIT_AURA) then
                    v:UNIT_AURA("UNIT_AURA", v.unit)
                end
            end
        end
 else
    for _, frames in pairs({"ElvUF_Target", "ElvUF_TargetTarget", "ElvUF_Pet", "ElvUF_Focus", "ElvUF_FocusTarget"}) do
        _G[frames].Hide = function() end
        _G[frames].unit = "player"
        _G[frames]:Show()
    end
    
    for i = 1, 5 do
		_G["ElvUF_Arena"..i].Hide = function() end
		_G["ElvUF_Arena"..i].unit = "player"
		_G["ElvUF_Arena"..i]:Show()
		_G["ElvUF_Arena"..i]:UpdateAllElements()
	end
	
	for i = 1, 4 do
		_G["ElvUF_Boss"..i].Hide = function() end
		_G["ElvUF_Boss"..i].unit = "player"
		_G["ElvUF_Boss"..i]:Show()
		_G["ElvUF_Boss"..i]:UpdateAllElements()
	end

end
end
