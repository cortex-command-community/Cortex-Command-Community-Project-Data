function RemoteGrenadeLauncherDetonate(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		ToHDFirearm(gun).Sharpness = 1;
	end
end

function RemoteGrenadeLauncherDelete(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		ToHDFirearm(gun).Sharpness = 2;
	end
end