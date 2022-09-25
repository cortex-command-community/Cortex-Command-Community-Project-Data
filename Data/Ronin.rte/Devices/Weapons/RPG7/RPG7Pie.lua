function RoninRPGSwitchAmmo(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun and actor:HasObject("Shovel") then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Ronin Shovel Shot";
		if gun.Magazine == nil or gun.Magazine.PresetName ~= magSwitchName then
			actor:RemoveInventoryItem("Shovel");
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
		end
	end
end