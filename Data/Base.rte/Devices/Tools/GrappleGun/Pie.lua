function GrapplePieRetract(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("GrappleMode", 1);
	end
end

function GrapplePieExtend(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("GrappleMode", 2);
	end
end