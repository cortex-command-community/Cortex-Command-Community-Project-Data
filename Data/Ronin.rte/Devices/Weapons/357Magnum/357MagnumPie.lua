function CowboyMode(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun then
		gun = ToHDFirearm(gun);
		if gun:NumberValueExists("CowboyMode") then
			gun:SetNumberValue("CowboyMode", 6);	-- Revert
		else
			gun:SetNumberValue("CowboyMode", 1);	-- Activate
		end
	end
end