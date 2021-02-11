function RoninCreateSandbag(actor)
	if actor and IsAHuman(actor) then
		actor = ToAHuman(actor);
		if actor:GetNumberValue("RoninShovelResource") >= 10 then
			actor:RemoveNumberValue("RoninShovelResource");
			actor:AddInventoryItem(CreateThrownDevice("Ronin.rte/Sandbag"));
			actor:EquipNamedDevice("Sandbag", true);
		else
			AudioMan:PlaySound("Base.rte/Sounds/GUIs/UserError.flac", actor.Pos);
		end
	end
end