function M79GrenadeLauncherFailsafeOff(pieMenuOwner, pieMenu, pieSlice)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin M79 Grenade Launcher Impact";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
			pieMenu:RemovePieSlicesByPresetName(pieSlice.PresetName);
			pieMenu:AddPieSlice(CreatePieSlice("M79 Turn On Failsafe", "Ronin.rte"), gun);
		end
	end
end

function M79GrenadeLauncherFailsafeOn(pieMenuOwner, pieMenu, pieSlice)
	local gun = pieMenuOwner.EquippedItem;
	if gun then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin M79 Grenade Launcher Bounce";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
			pieMenu:RemovePieSlicesByPresetName(pieSlice.PresetName);
			pieMenu:AddPieSlice(CreatePieSlice("M79 Turn Off Failsafe", "Ronin.rte"), gun);
		end
	end
end