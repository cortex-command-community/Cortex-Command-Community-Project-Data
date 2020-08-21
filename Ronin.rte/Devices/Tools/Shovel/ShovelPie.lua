function RoninCreateSandbag(actor)
	if actor and IsAHuman(actor) then
		actor = ToAHuman(actor);
		actor:AddInventoryItem(CreateThrownDevice("Ronin.rte/Sandbag"));
		actor:RemoveNumberValue("RoninShovelResource");

		actor:EquipNamedDevice("Sandbag", true);
	end
end