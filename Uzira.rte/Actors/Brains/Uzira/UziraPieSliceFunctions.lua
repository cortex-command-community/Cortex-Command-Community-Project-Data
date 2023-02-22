function EnableMinionSpawning(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("EnableMinionSpawning", 1);
	pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("DisableMinionSpawning", "Uzira.rte"));
end

function DisableMinionSpawning(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("EnableMinionSpawning", 0);
	pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("EnableMinionSpawning", "Uzira.rte"));
end

function MinionsGather(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("MinionsGather", 1);
	pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("MinionsStandby", "Uzira.rte"));
end

function MinionsStandby(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("MinionsGather", 0);
	pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("MinionsGather", "Uzira.rte"));
end

function MinionsFrenzy(pieMenu, pieSlice, pieMenuOwner)
	pieMenuOwner:SetNumberValue("MinionsFrenzy", 1);
	pieSlice.Enabled = false;
end