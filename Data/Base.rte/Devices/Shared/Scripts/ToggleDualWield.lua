function ToggleDualWield(actor)
	local device = ToAHuman(actor).EquippedItem;
	if device and IsHeldDevice(device) then
		local isDualWieldable = ToHeldDevice(device):IsDualWieldable();
		ToHeldDevice(device):SetDualWieldable(not isDualWieldable);
		ToHeldDevice(device):SetOneHanded(not isDualWieldable);
	end
end