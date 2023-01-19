function M79GrenadeLauncherFailsafeOff(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin M79 Grenade Launcher Impact";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
			pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("M79 Turn On Failsafe", "Ronin.rte"));
		end
	end
end

function M79GrenadeLauncherFailsafeOn(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin M79 Grenade Launcher Bounce";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
			pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("M79 Turn Off Failsafe", "Ronin.rte"));
		end
	end
end