function ToggleDualWield(pieMenu, pieSlice, pieMenuOwner)
	local device = pieMenuOwner.EquippedItem;
	if device and IsHeldDevice(device) then
		local isDualWieldable = ToHeldDevice(device):IsDualWieldable();
		ToHeldDevice(device):SetDualWieldable(not isDualWieldable);
		ToHeldDevice(device):SetOneHanded(not isDualWieldable);
	end
end