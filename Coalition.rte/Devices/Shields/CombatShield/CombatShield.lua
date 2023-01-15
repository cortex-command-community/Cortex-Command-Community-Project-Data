function Coalition_AttachCombatShield(self)
	local errorSound = CreateSoundContainer("Error", "Base.rte");
	local parent = ToAHuman(self:GetRootParent());
	local device = parent:Inventory();
	if device and device.ModuleName == self.ModuleName and IsHDFirearm(device) and not ToHDFirearm(device):IsOneHanded() then
		device = ToHDFirearm(device);
		for attachable in device.Attachables do
			if attachable:GetModuleAndPresetName() == "Coalition.rte/Combat Shield" then
				if parent:IsPlayerControlled() then
					errorSound:Play(self.Pos, parent:GetController().Player);
				end
				return;
			end
		end
		self.Frame = 1;
		device:AddAttachable(self:Clone(), Vector(math.floor(device.MuzzleOffset.X * 0.5) - 2, device.MuzzleOffset.Y));
		if device:HasScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua") then
			device:EnableScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua");
		else
			device:AddScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua");
		end
		self.ToDelete = true;
		parent:GetController():SetState(Controller.WEAPON_CHANGE_NEXT, true);
	elseif parent:IsPlayerControlled() then
		errorSound:Play(self.Pos, parent:GetController().Player);
	end
end
function Create(self)
	local parent = self:GetRootParent();
	if IsAHuman(parent) then
		parent = ToAHuman(parent);
		local attachedToGun = IsHDFirearm(self:GetParent());
		parent.PieMenu:GetFirstPieSliceByPresetName("Coalition Shield Detach PieSlice").Enabled = attachedToGun;
		parent.PieMenu:GetFirstPieSliceByPresetName("Coalition Shield Attach PieSlice").Enabled = not attachedToGun;
		if not attachedToGun and not parent:IsPlayerControlled() then
			Coalition_AttachCombatShield(self);
		end
	end
end
function CoalitionShieldAttach(pieMenu, pieSlice, pieMenuOwner)
	local device = pieMenuOwner.EquippedItem;
	if device and IsHeldDevice(device) then
		Coalition_AttachCombatShield(ToHeldDevice(device));
	end
end
function CoalitionShieldDetach(pieMenu, pieSlice, pieMenuOwner)
	local device = pieMenuOwner.EquippedItem;
	if device and IsHDFirearm(device) then
		device = ToHDFirearm(device);
		for attachable in device.Attachables do
			if attachable:GetModuleAndPresetName() == "Coalition.rte/Combat Shield" then
				pieMenuOwner.PieMenu:GetFirstPieSliceByPresetName("Coalition Shield Detach PieSlice").Enabled = false;
				pieMenuOwner.PieMenu:GetFirstPieSliceByPresetName("Coalition Shield Attach PieSlice").Enabled = true;
				if device:HasScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua") then
					device:DisableScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua");
				end
				attachable.Frame = 0;
				device:RemoveAttachable(attachable, true, true);
				break;
			end
		end
	end
end