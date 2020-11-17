function RoninCreateSandbag(actor)
	if actor and IsAHuman(actor) then
		actor = ToAHuman(actor);
		if actor:GetNumberValue("RoninShovelResource") >= 10 then
			actor:AddInventoryItem(CreateThrownDevice("Ronin.rte/Sandbag"));
			actor:EquipNamedDevice("Sandbag", true);
		end
		actor:RemoveNumberValue("RoninShovelResource");
	end
end