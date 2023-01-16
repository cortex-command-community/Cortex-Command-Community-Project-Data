function EnableMinionSpawning(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("EnableMinionSpawning", 1);
end

function DisableMinionSpawning(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("EnableMinionSpawning", 0);
end

function MinionsGather(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("MinionsGather", 1);
end

function MinionsStandby(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("MinionsGather", 0);
end

function MinionsFrenzy(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("MinionsFrenzy", 1);
end