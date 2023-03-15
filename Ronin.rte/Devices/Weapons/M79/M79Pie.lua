function M79GrenadeLauncherFailsafeOff(pieMenu, pieSlice, pieMenuOwner)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin M79 Grenade Launcher Impact";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			if gun.Magazine then
				gun.Magazine = CreateMagazine(magSwitchName, "Ronin.rte");
			end
			gun:SetNextMagazineName(magSwitchName);
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
			if gun.Magazine then
				gun.Magazine = CreateMagazine(magSwitchName, "Ronin.rte");
			end
			gun:SetNextMagazineName(magSwitchName);
			pieMenu:ReplacePieSlice(pieSlice, CreatePieSlice("M79 Turn Off Failsafe", "Ronin.rte"));
		end
	end
end