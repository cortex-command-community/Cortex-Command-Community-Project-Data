function ToggleDualWield(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun and IsHDFirearm(gun) then
		local isDualWieldable = ToHDFirearm(gun):IsDualWieldable();
		ToHDFirearm(gun):SetDualWieldable(not isDualWieldable);
		ToHDFirearm(gun):SetOneHanded(not isDualWieldable);
	end
end