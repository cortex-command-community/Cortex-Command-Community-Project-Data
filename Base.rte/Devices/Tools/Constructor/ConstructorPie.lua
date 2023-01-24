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
		pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("Constructor Spray Mode", "Base.rte"));
	end
end

function ConstructorSprayMode(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		ToMOSRotating(gun):SetStringValue("ConstructorMode", "Spray");
		pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("Constructor Dig Mode", "Base.rte"));
	end
end