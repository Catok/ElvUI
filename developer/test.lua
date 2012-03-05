--[[
	Going to leave this as my bullshit lua file.
	
	So I can test stuff.
]]

SLASH_TEST1 = "/testui"
SlashCmdList["TEST"] = function(msg)
 if msg == "hide" then
	for _, frames in pairs({"ElvUF_Target", "ElvUF_TargetTarget", "ElvUF_Pet", "ElvUF_Focus"}) do
        _G[frames].Hide = nil
    end
    
    for _, frames in pairs({"ElvUF_Arena"}) do
        for i = 1, 5 do
            _G[frames..i].Hide = nil
        end
    end
	
	for _, frames in pairs({"ElvUF_Boss"}) do
        for i = 1, 4 do
            _G[frames..i].Hide = nil
        end
    end
	
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
    for _, frames in pairs({"ElvUF_Target", "ElvUF_TargetTarget", "ElvUF_Pet", "ElvUF_Focus"}) do
        _G[frames].Hide = function() end
        _G[frames].unit = "player"
        _G[frames]:Show()
    end
    
    for _, frames in pairs({"ElvUF_Arena"}) do
        for i = 1, 5 do
            _G[frames..i].Hide = function() end
            _G[frames..i].unit = "player"
            _G[frames..i]:Show()
			_G[frames..i]:UpdateAllElements()
        end
    end
	
	for _, frames in pairs({"ElvUF_Boss"}) do
        for i = 1, 4 do
            _G[frames..i].Hide = function() end
            _G[frames..i].unit = "player"
            _G[frames..i]:Show()
			_G[frames..i]:UpdateAllElements()
        end
    end
end
end
