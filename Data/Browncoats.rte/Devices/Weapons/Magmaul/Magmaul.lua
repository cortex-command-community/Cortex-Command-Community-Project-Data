function OnPieMenu(item)
	if item and IsHDFirearm(item) and item.PresetName == "GL-01 Magmaul" then
		item = ToHDFirearm(item);
		if item.Magazine then
			--Remove corresponding pie slices if mode is already active
			if item.Magazine.PresetName == "Magazine GL-1 Fuel" then
				ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Fuel Bomb", "MagmaulFuelGrenade");
			elseif item.Magazine.PresetName == "Magazine GL-1 Fire" then
				ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Fire Bomb", "MagmaulFireGrenade");
			end
		end
	end
end