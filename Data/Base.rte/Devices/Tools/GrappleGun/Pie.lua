function GrapplePieRetract(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("GrappleMode", 1);
	end
end

function GrapplePieExtend(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		ToMOSRotating(gun):SetNumberValue("GrappleMode", 2);
	end
end