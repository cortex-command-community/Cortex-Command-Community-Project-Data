function Coalition_AttachCombatShield(self)
	local parent = ToAHuman(self:GetRootParent());
	
	for device in parent.Inventory do
		if device.ModuleName == self.ModuleName and IsHDFirearm(device) and not ToHDFirearm(device):IsOneHanded() then
			device = ToHDFirearm(device);
			
			local canAttachCombatShield = true;
			for attachable in device.Attachables do
				if attachable:GetModuleAndPresetName() == "Coalition.rte/Combat Shield" then
					canAttachCombatShield = false;
				end
			end
			
			if canAttachCombatShield then
				self.Frame = 1;
				parent.PieMenu:RemovePieSlicesByOriginalSource(self);
				device:AddAttachable(self:Clone(), Vector(math.floor(device.MuzzleOffset.X * 0.5) - 2, device.MuzzleOffset.Y));
				if device:HasScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua") then
					device:EnableScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua");
				else
					device:AddScript("Coalition.rte/Devices/Shields/CombatShield/Support.lua");
				end
				self.ToDelete = true;
				parent:EquipNamedDevice(device.ModuleName, device.PresetName, true);
				return;
			end
		end
	end
	if parent:IsPlayerControlled() then
		CreateSoundContainer("Error", "Base.rte"):Play(self.Pos, parent:GetController().Player);
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

function OnAttach(self, newParent)
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

function CoalitionShieldAttach(pieMenuOwner, pieMenu, pieSlice)
	local device = pieMenuOwner.EquippedItem;
	if device:GetModuleAndPresetName() ~= "Coalition.rte/Combat Shield" then
		device = pieMenuOwner.EquippedBGItem;
	end
	if device and IsHeldDevice(device) and device:GetModuleAndPresetName() == "Coalition.rte/Combat Shield" then
		Coalition_AttachCombatShield(ToHeldDevice(device));
	end
end

function CoalitionShieldDetach(pieMenuOwner, pieMenu, pieSlice)
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
				local removedAttachable = device:RemoveAttachable(attachable, false, false);
				pieMenuOwner:AddInventoryItem(removedAttachable:Clone())
				break;
			end
		end
	end
end