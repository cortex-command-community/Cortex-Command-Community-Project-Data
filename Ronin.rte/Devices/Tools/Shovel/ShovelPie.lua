function RoninCreateSandbag(pieMenu, pieSlice, pieMenuOwner)
	if pieMenuOwner:GetNumberValue("RoninShovelResource") >= 10 then
		pieMenuOwner = ToAHuman(pieMenuOwner);
		pieMenuOwner:RemoveNumberValue("RoninShovelResource");
		pieMenuOwner:AddInventoryItem(CreateThrownDevice("Ronin.rte/Sandbag"));
		pieMenuOwner:EquipNamedDevice("Sandbag", true);
	else
		local errorSound = CreateSoundContainer("Error", "Base.rte");
		errorSound:Play(pieMenuOwner.Pos, pieMenuOwner:GetController().Player);
	end
end