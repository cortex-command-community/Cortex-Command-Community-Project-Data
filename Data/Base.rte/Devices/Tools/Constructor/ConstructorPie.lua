function ConstructorModeCancel(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("BuildMode", 1);
	end
end

function ConstructorModeBuild(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("BuildMode", 2);
	end
end

function ConstructorDigMode(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		ToMOSRotating(gun):SetStringValue("ConstructorMode", "Dig");
	end
end

function ConstructorSprayMode(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		ToMOSRotating(gun):SetStringValue("ConstructorMode", "Spray");
	end
end