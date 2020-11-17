function OnPieMenu(item)
	if item and IsHDFirearm(item) and item.PresetName == "M79" then
		item = ToHDFirearm(item);
		if item.Magazine then
			--Remove corresponding pie slices if mode is already active
			if item.Magazine.PresetName == "Magazine Ronin M79 Grenade Launcher Impact" then
				ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Turn Off Failsafe", "M79GrenadeLauncherFailsafeOff");
			elseif item.Magazine.PresetName == "Magazine Ronin M79 Grenade Launcher Bounce" then
				ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Turn On Failsafe", "M79GrenadeLauncherFailsafeOn")
			end
		end
	end
end