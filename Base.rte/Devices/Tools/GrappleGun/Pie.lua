function GrapplePieRetract(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun.Sharpness = 1;
	end
end

function GrapplePieExtend(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun.Sharpness = 2;
	end
end