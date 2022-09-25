function RoninCreateSandbag(actor)
	if actor and IsAHuman(actor) then
		actor = ToAHuman(actor);
		if actor:GetNumberValue("RoninShovelResource") >= 10 then
			actor:RemoveNumberValue("RoninShovelResource");
			actor:AddInventoryItem(CreateThrownDevice("Ronin.rte/Sandbag"));
			actor:EquipNamedDevice("Sandbag", true);
		else
			local errorSound = CreateSoundContainer("Error", "Base.rte");
			errorSound:Play(actor.Pos, actor:GetController().Player);
		end
	end
end