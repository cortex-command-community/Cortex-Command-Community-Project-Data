function MagmaulFireGrenade(pieMenuOwner, pieMenu, pieSlice)
	local gun = pieMenuOwner.EquippedItem;
	if gun ~= nil then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine GL-1 Fire";
		if gun.Magazine == nil or (gun.Magazine ~= nil and gun.Magazine.PresetName ~= magSwitchName) then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
			pieMenu:RemovePieSlicesByPresetName(pieSlice.PresetName);
			pieMenu:AddPieSlice(CreatePieSlice("Magmaul Fuel Bomb", "Browncoats.rte"), gun);
		end
	end
end

function MagmaulFuelGrenade(pieMenuOwner, pieMenu, pieSlice)
	local gun = pieMenuOwner.EquippedItem;
	if gun ~= nil then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine GL-1 Fuel";
		if gun.Magazine == nil or (gun.Magazine ~= nil and gun.Magazine.PresetName ~= magSwitchName) then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
			pieMenu:RemovePieSlicesByPresetName(pieSlice.PresetName);
			pieMenu:AddPieSlice(CreatePieSlice("Magmaul Fire Bomb", "Browncoats.rte"), gun);
		end
	end
end