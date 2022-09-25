function M79GrenadeLauncherFailsafeOff(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin M79 Grenade Launcher Impact";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
		end
	end
end
function M79GrenadeLauncherFailsafeOn(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin M79 Grenade Launcher Bounce";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
		end
	end
end