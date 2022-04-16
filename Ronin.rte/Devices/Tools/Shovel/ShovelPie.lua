function RoninCreateSandbag(actor)
	if actor and IsAHuman(actor) then
		if actor:GetNumberValue("RoninShovelResource") >= 10 then
			actor = ToAHuman(actor);
			actor:RemoveNumberValue("RoninShovelResource");
			actor:AddInventoryItem(CreateThrownDevice("Ronin.rte/Sandbag"));
			actor:EquipNamedDevice("Sandbag", true);
			actor.PieMenu:GetFirstPieSliceByPresetName("Ronin Shovel Fill Sandbag PieSlice").Enabled = false;
		else
			local errorSound = CreateSoundContainer("Error", "Base.rte");
			errorSound:Play(actor.Pos, actor:GetController().Player);
		end
	end
end