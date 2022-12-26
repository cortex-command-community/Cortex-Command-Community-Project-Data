function ConstructorModeCancel(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("BuildMode", 1);
	end
end

function ConstructorModeBuild(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("BuildMode", 2);
	end
end

function ConstructorDigMode(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		ToMOSRotating(gun):SetStringValue("ConstructorMode", "Dig");
		pieMenu:RemovePieSlicesByPresetName(pieSlice.PresetName);
		pieMenu:AddPieSlice(CreatePieSlice("Constructor Spray Mode", "Base.rte"), gun);
	end
end

function ConstructorSprayMode(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		ToMOSRotating(gun):SetStringValue("ConstructorMode", "Spray");
		pieMenu:RemovePieSlicesByPresetName(pieSlice.PresetName);
		pieMenu:AddPieSlice(CreatePieSlice("Constructor Dig Mode", "Base.rte"), gun);
	end
end