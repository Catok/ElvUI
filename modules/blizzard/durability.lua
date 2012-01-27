local E, L, DF = unpack(select(2, ...))
local B = E:GetModule('Blizzard');

function B:PositionDurabilityFrame()
	hooksecurefunc(DurabilityFrame,"SetPoint",function(self,_,parent)
		if (parent == "MinimapCluster") or (parent == _G["MinimapCluster"]) then
			DurabilityFrame:ClearAllPoints()
			DurabilityFrame:Point("RIGHT", Minimap, "RIGHT")
			DurabilityFrame:SetScale(0.6)
		end
	end)
end