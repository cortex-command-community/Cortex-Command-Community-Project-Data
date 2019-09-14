function GrapplePieRetract(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun.Sharpness = 1;
	end
end

function GrapplePieDetract(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun.Sharpness = 2;
	end
end

function GrapplePieStop(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun.Sharpness = 0;
	end
end